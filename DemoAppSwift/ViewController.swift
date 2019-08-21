import UIKit

class ViewController: UIViewController {

    @IBOutlet var recognitionResultLabel: UILabel!
    @IBOutlet var fromMicButton: UIButton!
    @IBOutlet var fromFileButton: UIButton!
    
    var speechKey: String!
    var serviceRegion: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Paste your values from the portal
        // Note: this should not be done in a production app, as it is completely insecure!
        speechKey = "";
        serviceRegion = "";
    }
    
    
    @IBAction func fromMicButtonClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.recognizeFromMic()
        }
    }

    func recognizeFromMic() {
        var speechConfig: SPXSpeechConfiguration?
        do {
            try speechConfig = SPXSpeechConfiguration(subscription: speechKey, region: serviceRegion)
        } catch {
            print("error \(error) happened")
            speechConfig = nil
        }
        speechConfig?.speechRecognitionLanguage = "en-US"
        speechConfig?.outputFormat = .detailed
        
        let audioConfig = SPXAudioConfiguration()
        let reco = try! SPXSpeechRecognizer(speechConfiguration: speechConfig!, audioConfiguration: audioConfig!)
        
        reco.addRecognizingEventHandler() {reco, evt in
            print("intermediate recognition result: \(evt.result.text ?? "(no result)")")
            self.updateRecognitionResultLabel(text: evt.result.text, color: .gray)
        }
        
        updateRecognitionResultLabel(text: "Listening ...", color: .gray)
        print("Listening...")
        
        let result = try! reco.recognizeOnce()
        print("recognition result: \(result.text ?? "(no result)")")
        updateRecognitionResultLabel(text: result.text, color: .black)
    }

    func updateRecognitionResultLabel(text: String?, color: UIColor) {
        DispatchQueue.main.async {
            self.recognitionResultLabel.text = text
            self.recognitionResultLabel.textColor = color
        }
    }
}
