<?php return array(
    'root' => array(
        'name' => 'twaydev/backend',
        'pretty_version' => '1.0.0',
        'version' => '1.0.0.0',
        'reference' => null,
        'type' => 'library',
        'install_path' => __DIR__ . '/../../',
        'aliases' => array(),
        'dev' => true,
    ),
    'versions' => array(
        'monorepo-php/monorepo' => array(
            'pretty_version' => '12.4.5',
            'version' => '12.4.5.0',
            'reference' => '058cd7781afb5b216c2ad84e05e79053c8a7680c',
            'type' => 'library',
            'install_path' => __DIR__ . '/../monorepo-php/monorepo',
            'aliases' => array(),
            'dev_requirement' => true,
        ),
        'twaydev/backend' => array(
            'pretty_version' => '1.0.0',
            'version' => '1.0.0.0',
            'reference' => null,
            'type' => 'library',
            'install_path' => __DIR__ . '/../../',
            'aliases' => array(),
            'dev_requirement' => false,
        ),
    ),
);
