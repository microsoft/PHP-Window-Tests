<?php

if ($argc != 3) {
    printf("usage: php %s <php1> <php2>\n", $argv[0]);
    exit(1);
}

$php1_name = $argv[1];
$php2_name = $argv[2];

$php1_nocache_dir = "iis\\$php1_name";
$php1_opcache_dir = "iis\\$php1_name-opcache";
$php1_wincache_dir = "iis\\$php1_name-wincache";
$php2_nocache_dir = "iis\\$php2_name";
$php2_opcache_dir = "iis\\$php2_name-opcache";
$php2_wincache_dir = "iis\\$php2_name-wincache";


$appnames = array(
    "Helloworld"
    ,"Wordpress"
    ,"Drupal"
    ,"Joomla"
    ,"Mediawiki"
    ,"Symfony"
    ,"Laravel"
    ,"Yii"
    //,"Phalcon"
);
$vs = array(32, 16, 8);
$versions = parse_ini_file('./iis/versions.ini');

$error_counts = [];
$tps_counts = [];
$request_counts = [];

function read_file($build_scenario_key, $dir, $app_v_key)
{
    global $error_counts, $tps_counts, $request_counts;

    $xdoc = new DOMDocument();

    $fname = "$dir\\$app_v_key.xml";

    $key = "$build_scenario_key\\$app_v_key";

    if (!file_exists($fname)) {
        $error_counts[$key] = '';
        $tps_counts[$key] = '';
        $request_counts[$key] = '';
        return;
    }

    $file = realpath($fname);

    $xdoc->load($file);

    $xpath = new DOMXPath($xdoc);

    $error_count = $xpath->query("//report/section[@name='summary']/table/item/data[@name='terrors']")->item(0)->textContent;
    $tps_count = $xpath->query("//report/section[@name='summary']/table/item/data[@name='tps']")->item(0)->textContent;
    $request_count = $xpath->query("//report/section[@name='details']/table[@name='requeststats']/item/data[@name='requests']")->item(0)->textContent;

    $error_counts[$key] = $error_count;
    $tps_counts[$key] = $tps_count;
    $request_counts[$key] = $request_count;
}

function calc_gain($base, $test)
{
    $base = (float) $base;
    $test = (float) $test;

    if ($base == 0) {
        return ['value' => '', 'class' => ''];
    }

    $r =  (($test / $base) -1 ) * 100;

    if ($r > 7) {
        $class="gainpos";
    } elseif ($r > 2) {
        $class="gainpossmall";
    } elseif ($r < -7) {
        $class="gainneg";
    } elseif ($r < -2) {
        $class="gainnegsmall";
    } else {
        $class = '';
    }

    return ['value' => number_format($r, 2, '.', ''), 'class' => $class];
}

function render($_template, $_bag)
{
    extract($_bag);
    include $_template;
}

foreach ($appnames as $app_name) {
    foreach ($vs as $v) {
        read_file("php1_nocache", $php1_nocache_dir, "$app_name-$v");
        read_file("php1_opcache", $php1_opcache_dir, "$app_name-$v");
        read_file("php2_nocache", $php2_nocache_dir,  "$app_name-$v");
        read_file("php2_opcache", $php2_opcache_dir, "$app_name-$v");
        read_file("php1_wincache", $php1_wincache_dir, "$app_name-$v");
        read_file("php2_wincache", $php2_wincache_dir, "$app_name-$v");
    }
}

$appresults = [];
foreach ($appnames as $app_name) {
    $appresults["{$app_name} {$versions[$app_name]}"] = [];
    foreach ($vs as $i => $v) {
        $app_v_key = "$app_name-$v";
        $php1_nocache_tps = $tps_counts["php1_nocache\\$app_v_key"];
        $php2_nocache_tps = $tps_counts["php2_nocache\\$app_v_key"];
        $gain_nocache = calc_gain($php1_nocache_tps, $php2_nocache_tps);
        $php1_opcache_tps = $tps_counts["php1_opcache\\$app_v_key"];
        $php2_opcache_tps = $tps_counts["php2_opcache\\$app_v_key"];
        $gain_opcache = calc_gain($php1_opcache_tps, $php2_opcache_tps);
        $php1_wincache_tps = $tps_counts["php1_wincache\\$app_v_key"];
        $php2_wincache_tps = $tps_counts["php2_wincache\\$app_v_key"];
        $gain_wincache = calc_gain($php1_wincache_tps, $php2_wincache_tps);
        $appresults["{$app_name} {$versions[$app_name]}"][$i] = compact('v', 'php1_nocache_tps', 'php2_nocache_tps', 'gain_nocache',
            'php1_opcache_tps', 'php2_opcache_tps', 'gain_opcache',
            'php1_wincache_tps', 'php2_wincache_tps', 'gain_wincache');
    }
}

$errors = [];
foreach (array_keys($error_counts) as $key) {
    $e_count = $error_counts[$key];
    $r_count = $request_counts[$key];
    if ($e_count > 0) {
        $errors[$key] = compact('e_count', 'r_count');
    }
}

$bag = compact('php1_name', 'php2_name', 'appresults', 'errors');
array_walk_recursive(
    $bag,
    function (&$value, $key) {
        $value = htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
    }
);
render(__DIR__ . '/report_iis.phtml', $bag);
