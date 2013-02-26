<?php
function smarty_function_mtcontactformstaticlink($args, &$ctx) {
    require_once 'function.mtstaticwebpath.php';
    $type = isset($args['type']) ? strtoupper($args['type']) : '';
    $html = empty($args['html']) ? 0 : (int) $args['html'];
    $bf = array();
    foreach (array('jQuery', 'jQueryUI', 'default_style') as $k => $v)
        $bf[$v] = 1 << $k;
    $whole = (1 << count($bf)) - 1;
    $require = preg_match('/\d+/', isset($args['require']) ? $args['require'] : $whole, $m)
             ? (int) $m[0] : $whole;
    $delim = isset($args['delimiter']) ? $args['delimiter'] : PHP_EOL;
    $staticwebpath = smarty_function_mtstaticwebpath($args, $ctx);
    $mtml = '';
    if ($type !== 'JS') {
        $close = $html === 0 ? ' /' : '';
        $type_attr = $html === 5 ? '' : ' type="text/css"';
        $requires = array();
        if ($require & $bf['jQueryUI'])      $requires[] = 'smoothness/jquery-ui.custom';
        if ($require & $bf['default_style']) $requires[] = 'default-style';
        foreach ($requires as $v)
            $mtml .= <<<MTML
<link rel="stylesheet" href="${staticwebpath}addons/ContactForm.pack/css/$v.css"$type_attr$close>$delim
MTML;
    }
    if ($type !== 'CSS') {
        $type_attr = $html === 5 ? '' : ' type="text/javascript"';
        $requires = array();
        if ($require & $bf['jQuery'])        $requires[] = 'jquery.min';
        if ($require & $bf['jQueryUI'])      $requires[] = 'jquery-ui.custom.min';
        if ($require & $bf['default_style']) $requires[] = 'default-style';
        foreach ($requires as $v)
            $mtml .= <<<MTML
<script$type_attr src="${staticwebpath}addons/ContactForm.pack/js/$v.js"></script>$delim
MTML;
    }
    return rtrim($mtml, $delim);
}
?>
