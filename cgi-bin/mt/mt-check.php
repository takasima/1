<?php
// このメッセージが Web ブラウザから見える場合、PHP が動作していません。
ini_set('display_errors', '0');
define('CONFIG_FILE', 'mt-config.cgi');
$mode = get_mode();
?>
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8" />
	<title>Movable Type システムチェック [mt-check.php]</title>
	<style type="text/css">
	body {
		margin: 0;
		padding: 0;
		background-color: #fffffc;
		color: #2b2b2b;
		font-size: 13px;
		font-family: Helvetica, "Helvetica Neue", Arial, sans-serif;
		line-height: 1.2;
	}
	#header {
		position: relative;
		padding: 1px;
		background-color: #2b2b2b;
	}
	#content {
		margin: 20px 20px 100px;
	}
	#content > :first-child {
		margin-bottom: -1.5em;
	}
	h1 {
		margin: 8px 10px;
		color: #f8fbf8;
	}
	h2 {
		margin: 2em 0 0.5em;
		font-size: 24px;
		font-weight: normal;
	}
	h3 {
		margin-bottom: 0;
		font-size: 16px;
	}
	textarea {
		overflow: auto;
		width: 99%;
		height: 150px;
		padding: 0.2em 0.25em;
		margin: 10px 0 0;
		border: 1px solid #c0c6c9;
		background-color: #f3f3f3;
		color: #7b7c7d;
		font-size: 95%;
		font-family: monospace;
	}
	.msg {
		position: relative;
		margin: 10px 0;
		padding: 0.5em 0.75em;
	}
	.msg-info {
		background-color: #e6eae3;
	}
	.msg-warning {
		background-color: #fef263;
	}
	.installed {
		margin: 10px 0;
		color: #9ea1a3;
	}
	</style>
</head>

<body>

<div id="header">
<h1>Movable Type システムチェック [mt-check.php]</h1>
</div>

<div id="content">

<?php if (is_config_file() && !isset($mode['DynamicMTMLDebugMode'])) { ?>

<p class="meg-text">構成ファイル (mt-config.cgi) がすでに存在するため、このスクリプトは無効になっています。</p>

<?php } else { ?>

<p class="msg msg-info">mt-check.php はシステムの構成を確認し、Movable Type のダイナミックパブリッシングおよび PowerCMS の DynamicMTML が動作するために必要な PHP 環境がそろっていることを確認するためのスクリプトです。
なお、各関数が利用可能であることのほかに、Web サーバーとして Apache を使用している場合 .htaccess ファイルが利用可能である必要があります。</p>

<h2>システム情報</h2>
<ul>
<li><strong>OS</strong>: <code><?php echo PHP_OS; ?></code></li>
<li><strong>Web サーバー</strong>: <code><?php echo PHP_SAPI; ?></code></li>
<li><strong>PHP バージョン</strong>: <code><?php echo PHP_VERSION; ?></code></li>
<li><strong>php.ini のパス</strong>:
<?php if ( function_exists( 'php_ini_loaded_file' ) ): ?>
<code><?php echo htmlspecialchars(php_ini_loaded_file(), ENT_NOQUOTES, 'UTF-8'); ?></code>
<?php else: ?>
<span class="installed">検出できませんでした。</span>
<?php endif; ?>
</li>
<li><strong>現在のディレクトリ</strong>: <code><?php echo htmlspecialchars($_SERVER['SCRIPT_FILENAME'], ENT_NOQUOTES, 'UTF-8'); ?></code></li>
<li><strong>ドキュメントルート</strong>: <code><?php echo htmlspecialchars($_SERVER['DOCUMENT_ROOT'], ENT_NOQUOTES, 'UTF-8'); ?></code></li>
</ul>

<?php if (version_compare(PHP_VERSION, '5', '<')) { ?>
<p class="msg msg-warning">お使いのサーバーにインストールされている PHP <?php echo PHP_VERSION; ?> は、Movable Type でサポートされている最低限のバージョンを満たしていません。PHP をアップグレードしてください。</p>
<?php } ?>

<h2>必須関数</h2>

<p class="msg msg-info">Movable Type のダイナミックパブリッシングおよび PowerCMS の DynamicMTML が動作するためにはこれらの関数がインストールされ、利用可能である必要があります。</p>

<h3>mb_convert_encoding</h3>

<?php if (function_exists('mb_convert_encoding')) { ?>
<p class="installed">mb_convert_encoding 関数は利用できます。</p>
<?php } else { ?>
<p class="msg msg-warning">mb_convert_encoding 関数は利用できません。</p>
<?php } ?>

<h3>imagejpeg</h3>

<?php if (function_exists('imagejpeg')) { ?>
<p class="installed">imagejpeg 関数は利用できます。</p>
<?php } else { ?>
<p class="msg msg-warning">imagejpeg 関数は利用できません。GD が利用できないか、GD が JPEG をサポートしていない可能性があります。</p>
<?php } ?>

<h2>環境情報</h2>

<p class="msg msg-info">Movable Type のダイナミックパブリッシングおよび PowerCMS の DynamicMTML が動作するか、PHP の環境設定をチェックします。</p>

<h3>open_basedir</h3>

<?php $result = is_open_basedir(); ?>
<?php if ($result['flag']) { ?>
<p class="installed"><?php echo $result['message']; ?></p>
<?php } else { ?>
<p class="msg msg-warning"><?php echo $result['message']; ?></p>
<?php } ?>

<h3>date.timezone</h3>

<?php $result = is_timezone(); ?>
<?php if ($result['flag']) { ?>
<p class="installed"><?php echo $result['message']; ?></p>
<?php } else { ?>
<p class="msg msg-warning"><?php echo $result['message']; ?></p>
<?php } ?>

<h3>memory_limit</h3>

<?php $result = is_memory_limit(); ?>
<?php if ($result['flag']) { ?>
<p class="installed"><?php echo $result['message']; ?></p>
<?php } else { ?>
<p class="msg msg-warning"><?php echo $result['message']; ?></p>
<?php } ?>

<?php } ?>

</div>

</body>
</html>

<?php

function is_config_file() {
	if (file_exists(CONFIG_FILE)) {
		return TRUE;
	} else {
		return FALSE;
	}
}

function get_mode() {
	$mode = array();
	if (is_config_file()) {
		$config = file_get_contents(CONFIG_FILE);
		preg_match_all('/^\s*([^\s#]\S*)\s+(.*?)\s*$/m', $config, $m, PREG_SET_ORDER);
		$config = array();
		foreach ($m as $v) $config[strtolower($v[1])] = $v[2];

		if ($config['dynamicmtmldebugmode']) {
			$mode['DynamicMTMLDebugMode'] = 1;
		}
	}
	return $mode;
}

function is_open_basedir() {
	$result = array();
	if (function_exists('ini_get_all')) {
		$ini = ini_get_all();
		if (array_key_exists('open_basedir', $ini) && array_key_exists('local_value', $ini['open_basedir']) && empty($ini['open_basedir']['local_value'])) {
			$result = array(
				'flag' => TRUE,
				'message' => 'open_basedir での制限は行われていません。Movable Type のダイナミックパブリッシングおよび PowerCMS の DynamicMTML の動作に問題ありません。'
			);
		} else {
			$result = array(
				'flag' => FALSE,
				'message' => 'open_basedir が ' . $ini['open_basedir']['local_value'] . ' に制限されています。Movable Type のダイナミックパブリッシングおよび PowerCMS の DynamicMTML が動作しない可能性があります。'
			);
		}
	} else {
		$result = array(
			'flag' => FALSE,
			'message' => 'php.ini の設定が取得できませんでした。'
		);
	}
	return $result;
}

function is_timezone() {
	$result = array();
	if (function_exists('ini_get')) {
		$ini = ini_get('date.timezone');
		if (!empty($ini)) {
			$result = array(
				'flag' => TRUE,
				'message' => 'タイムゾーンは '. $ini .' に設定されています。'
			);
		} else {
			$result = array(
				'flag' => FALSE,
				'message' => 'タイムゾーンが設定されていません。Movable Type のダイナミックパブリッシングおよび PowerCMS の DynamicMTML を正しく動作させるためにタイムゾーンを設定してください。'
			);
		}
	} else {
		$result = array(
			'flag' => FALSE,
			'message' => 'php.ini の設定が取得できませんでした。'
		);
	}
	return $result;
}

function is_memory_limit() {
	$result = array();
	if (function_exists('ini_get')) {
		$ini = ini_get('memory_limit');
		if (!empty($ini)) {
			$result = array(
				'flag' => TRUE,
				'message' => 'memory_limit は '. $ini .' に設定されています。'
			);
		} else {
			$result = array(
				'flag' => FALSE,
				'message' => 'memory_limit が設定されていません。'
			);
		}
	} else {
		$result = array(
			'flag' => FALSE,
			'message' => 'php.ini の設定が取得できませんでした。'
		);
	}
	return $result;
}
?>
