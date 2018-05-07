
source 'https://github.com/CocoaPods/Specs.git'
#私有Spec Pod
source 'git@172.28.1.116:iOS/EKOSDKSpecs.git'

platform :ios, '8.0'

def eko_pods


end

def third_pods

end

project 'EKOAudio.xcodeproj'

target 'EKOAudio' do
    
    eko_pods

    third_pods

target 'EKOAudioTests' do
    inherit! :search_paths
    
    eko_pods

    third_pods

    end

end

