Pod::Spec.new do |spec|
    spec.name                     = 'shared'
    spec.version                  = '2.0.0'
    spec.homepage                 = 'Link to the Shared Module homepage'
    spec.source                   = { :http=> ''}
    spec.authors                  = 'RE.DOCTOR'
    spec.license                  = 'proprietary'
    spec.summary                  = 'RE.DOCTOR SDK'
    spec.vendored_frameworks      = 'build/cocoapods/framework/shared.framework'
    spec.libraries                = 'c++'
    spec.ios.deployment_target = '14.1'
    spec.dependency 'PLMLibTorchWrapper', '0.5.0'
                
    spec.pod_target_xcconfig = {
        'KOTLIN_PROJECT_PATH' => ':shared',
        'PRODUCT_MODULE_NAME' => 'shared',
    }
end
