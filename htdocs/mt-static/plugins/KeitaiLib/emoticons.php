<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<?php
    require_once( 'keitailib_util.php' );
    $size = $_GET[ 'size' ];
    $lang = $_GET[ 'lang' ];
    $edit_field = '';
    if ( isset ($_GET[ 'edit_field' ]) ) {
        $edit_field = $_GET[ 'edit_field' ];
        $edit_field = htmlspecialchars( $edit_field );
        $edit_field = __keitailib_encode_js( $edit_field );
    }
    $size = htmlspecialchars( $size );
    $lang = htmlspecialchars( $lang );
    if (! ctype_digit( $size ) ) {
        $size = 16;
    }
    if (! $lang ) {
        $lang = 'en_us';
    }
    $page_title = 'Inset Emoticon';
    $button_label = 'Cancel';
    if ( $lang == 'ja' ) {
        $page_title = '絵文字の挿入';
        $button_label = 'キャンセル';
    }
    $secure = empty( $_SERVER[ 'HTTPS' ] ) ? '' : 's';
    $base   = "http{$secure}://{$_SERVER[ 'HTTP_HOST' ]}";
    $port   = (int) $_SERVER[ 'SERVER_PORT' ];
    if (! empty( $port ) && $port !== ( $secure === '' ? 80 : 443 ) ) $base .= ":$port";
    $base .= dirname( $_SERVER['PHP_SELF'] ) . '/images/' . $size . '/';
    require_once( 'emoticon_table.php' );
?>
<html id="dialog">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title><?php echo $page_title;?> | Movable Type</title>
        <link rel="stylesheet" href="../../css/main.css" type="text/css" />
        <!--[if IE]>
        <link rel="stylesheet" href="../../css/hacks/ie.css" type="text/css" />
        <![endif]-->
        <!--[if lte IE 6]>
        <link rel="stylesheet" href="../../css/hacks/ie6.css" type="text/css" />
        <![endif]-->
        
  <script type="text/javascript" src="../../jquery/jquery.js"></script>
  <script type="text/javascript" src="../../js/common/Core.js"></script>
  <script type="text/javascript" src="../../js/common/JSON.js"></script>
  <script type="text/javascript" src="../../js/common/Timer.js"></script>
  <script type="text/javascript" src="../../js/common/Cookie.js"></script>
  <script type="text/javascript" src="../../js/common/DOM.js"></script>
  <script type="text/javascript" src="../../js/common/Devel.js"></script>
  <script type="text/javascript" src="../../js/common/Observable.js"></script>
  <script type="text/javascript" src="../../js/common/Autolayout.js"></script>
  <script type="text/javascript" src="../../js/common/Component.js"></script>
  <script type="text/javascript" src="../../js/common/List.js"></script>
  <script type="text/javascript" src="../../js/common/App.js"></script>
  <script type="text/javascript" src="../../js/common/Cache.js"></script>
  <script type="text/javascript" src="../../js/common/Client.js"></script>
  <script type="text/javascript" src="../../js/common/Template.js"></script>
  <script type="text/javascript" src="../../js/tc.js"></script>
  <script type="text/javascript" src="../../js/tc/tableselect.js"></script>
  <script type="text/javascript" src="../../jquery/jquery.validate.min.js"></script>
  <script type="text/javascript" src="../../jquery/jquery.json.js"></script>
  <script type="text/javascript" src="../../jqueryui/jquery-ui.js"></script>
  <script type="text/javascript" src="../../js/tc/client.js"></script>
  <script type="text/javascript" src="../../js/dialog.js"></script>
  <script type="text/javascript" src="../../js/assetdetail.js"></script>
        
<script type="text/javascript">
    /* <![CDATA[ */
    function dialogClose(data) {
        if (!data) {
            parent.jQuery.fn.mtDialog.close();
            return;
        }
    }
    // var tableSelect;
    var dlg;
    function init() {
        // setup
        dlg = new Dialog.Simple( "list-emoticon" );
        dlg.open({}, dialogClose);
    }
    /* ]]> */
</script>
  <script type="text/javascript" src="../../mt.js"></script>
  <link rel="stylesheet" href="../../styles_ja.css" />
  <script type="text/javascript" src="../../mt_ja.js" charset="utf-8"></script>
  <script type="text/javascript" src="../../jquery/jquery.mt.js?v=5.1"></script>
<script type="text/javascript">
    function insert_emoticon(src,alt,size){
        src = '<?php echo $base;?>' + src + '.gif';
        <?php
            if ( $lang != 'ja' ) {
                echo 'alt = src;';
            }
        ?>
        edit_field = '<?php echo $edit_field;?>';
        src = '<img src="' + src + '" alt="' + alt + '" width="<?php echo $size;?>" height="<?php echo $size;?>" />';
        if ( edit_field ) {
            window.parent.app.insertHTML(src,edit_field);
        } else {
            window.parent.app.insertHTML(src);
        }
        dialogClose();
    }
</script>
    </head>
    <body id="" class="dialog dialog-screen insert-asset-dialog">
    <div id="container">
        <div id="content">
        <div id="content-header">
            <h1 style="font-size:1.5em"><?php echo $page_title;?></h1>
        </div>
            <div id="list-emoticon-dialog">
                <div id="emoticon" class="msg msg-info" style="letter-spacing:5px;line-height:2.2em">
                <?php
                foreach ( $emoticon_table as $src => $alt ) {
                    if (! $lang == 'ja' ) {
                        $alt = $src;
                    }
                    echo '<a href="javascript:void(0)" onclick="insert_emoticon';
                    echo "('$src','$alt')\"><img alt=\"$alt\" src=\"images/$size/$src.gif\" ";
                    echo "width=\"$size\" height=\"$size\" /></a>\n";
                }
                ?>
                </div>
                <div class="actions-bar">
                    <form action="" method="get" onsubmit="return false">
                        <button
                           type="submit"
                           accesskey="x"
                           class="button cancel action mt-close-dialog"
                           title="<?php echo $button_label;?> (x)"
                           ><?php echo $button_label;?></button>
                    </form>
                </div>
            </div>
    </div>
<div id="bootstrapper" class="hidden"></div>
        </div><!-- /content -->
    </div><!-- /container -->
<script type="text/javascript">
/* <![CDATA[ */
App.bootstrapInline( false );
jQuery(function() {

    init();

    jQuery.mtAddEdgeClass();
    jQuery('button.mt-close-dialog').click(function() {
        parent.jQuery.fn.mtDialog.close();
    });
    jQuery('input').each(function() {
        jQuery(this).addClass(jQuery(this).attr('type'));
    });

});
/* ]]> */
</script>
    </body>
</html>