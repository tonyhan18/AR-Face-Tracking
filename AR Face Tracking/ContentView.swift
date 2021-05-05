//
//  ContentView.swift
//  AR Face Tracking
//
//  Created by 한찬희 on 2021/05/05.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    //모델을 가지고 온것을 ARView에 붙여주자
    @State private var anchorEntity = AnchorEntity()
    var body: some View {
        return ARViewContainer(anchorEntity: $anchorEntity).edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    //ContentView에서 model을 받아오자
    @Binding var anchorEntity : AnchorEntity
    
    //Coordinator을 사용하기 위해 아래의 함수를 정의
    func makeCoordinator() -> Coordinator{
        Coordinator(self)
    }
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
    
        let config = ARFaceTrackingConfiguration()
        //몇개까지 얼굴을 추적할지 정해놓는다. 여기에서 default설정시 1개만 체크한다.
        config.maximumNumberOfTrackedFaces = 1
        
        //아래의 방식으로 몇개의 기기를 지원하는지 확인할 수 있다.
        print(ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces)
        
        //아래의 코드로 앱을 작동시킬 수 있다.
        //arView.session.run(confg)
        arView.session.run(config)
        //아래를 정의하여서 Coordinator 클래스에서 session함수를 사용할 수 있게 된다.
        arView.session.delegate = context.coordinator
        return arView
        
    }
    
    //받아온 모델을 View에 붙여주기, 업데이트 해주기
    func updateUIView(_ uiView: ARView, context: Context) {
        uiView.scene.anchors.append(anchorEntity)
    }
    
}

//session을 사용하기 위해서 다음을 선언
class Coordinator : NSObject, ARSessionDelegate{
    //우리는 arViewContainer을 통해서 anchorEntity에 접근가능해진다.
    var arViewContainer : ARViewContainer!
    //모델가져오기
    let model = try! Experience.loadFace()//Experience.loadFace()

    var isMouthOpen = false
    
    init(_ control : ARViewContainer)
    {
        self.arViewContainer = control
    }
    
    //모델을 추가하는 session
    func session(_ session: ARSession, didAdd anchors: [ARAnchor])
    {
        //모델 가져온거 추가하기
        arViewContainer.anchorEntity.addChild(model)
    }
    
    //얼굴 움직임 체크하기
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        //추적하는 대상 첫번째것을 가지고 와서 ARFaceAnchor type으로 변환해준다.
        guard let faceAnchor = anchors.first as? ARFaceAnchor else{return}
        
        //아래의 방식으로 입이 열리었는지를 실시간으로 체크할 수 있다. 이때 값을 Float로 받아왔다.
        let eyeLBlink = faceAnchor.blendShapes[.eyeBlinkLeft] as! Float
        let eyeRBlink = faceAnchor.blendShapes[.eyeBlinkRight] as! Float
        //print(mouthOpen)
        
        if(eyeLBlink > 0.5 && eyeRBlink > 0.5 && !isMouthOpen)
        {
            //입 열었을때의 action 설정하기
            print("입 열었음")
            isMouthOpen = true
            model.notifications.anim.post()
        }
        if(eyeLBlink < 0.5 && eyeRBlink < 0.5 && isMouthOpen)
        {
            print("입 닫혔음")
            isMouthOpen = false;
            model.stopAllAnimations()
        }
    }
}
