//
//  CreatePostVC.swift
//  TikTok
//
//  Created by Osaretin Uyigue on 10/29/20.
//  Copyright © 2020 Osaretin Uyigue. All rights reserved.
//

import UIKit
import Photos
import AVKit
import AVFoundation
//import SVProgressHUD
fileprivate let cameraCellReuseIdentifier = "cameraCellReuseIdentifier"
fileprivate let templatesCellReuseIdentifier = "templatesCellReuseIdentifier"
fileprivate let headerReuseIdentifier = "headerReuseIdentifier"
fileprivate let footerReuseIdentifier = "footerReuseIdentifier"
class CreatePostVC: UIViewController {
    
    //
    //MARK: - Init
    deinit {
        print("CreatePostVC deinit")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setUpViews()
    }
    

  
    
    override func viewDidDisappear(_ animated: Bool) {
       super.viewDidDisappear(animated)
       stopSession()
   }
    
    //MAKR:- CONTINUE HERE
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        handleChangeMediaView(alpha: 1)
    }
    
    
    //MARK: - Properties
    override var prefersStatusBarHidden: Bool {
         return true
     }
    
    fileprivate var isMediaPickerOpen = false
    fileprivate var thumbnailImage: UIImage?
    fileprivate var maxVidDurationExhasuted = false
    fileprivate var currentMaxRecordingDuration: Int = 15 {
        didSet {
            recordingTimeLabel.text = "\(currentMaxRecordingDuration)s"
        }
    }
    let photoOutput = AVCapturePhotoOutput()
    let movieOutput = AVCaptureMovieFileOutput()
    let captureSession = AVCaptureSession()
    var flashMode: Bool = false
    var autoflashMode: Bool = false
    var activeInput: AVCaptureDeviceInput!
    var outPutURL: URL!
    fileprivate var recordedClips = [VideoClips]()
    
    fileprivate var videoDurationOfLastClip = 0 //
    fileprivate var totalRecordedTime_In_Minutes = 0
    fileprivate var total_RecordedTime_In_Secs = 0
    fileprivate weak var recordingTimer: Timer?

    
    
    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    var currentCameraDevice: AVCaptureDevice?
    lazy var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    
    fileprivate let captureButtonDimension: CGFloat = 68
    
    let segmentedProgressViewPadding: CGFloat = 17.5
     
    lazy var segmentedProgressView = SegmentedProgressView(width: view.frame.width - segmentedProgressViewPadding)

    fileprivate let buttonsDimension: CGFloat = 26//28
    fileprivate let buttonsRightPadding: CGFloat = 17
    
    fileprivate let mediaPickerView: MediaPickerView = {
        let view = MediaPickerView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] //layerMinXMinYCorner = top left, layerMaxXMinYCorner = top left
        return view
    }()

    
     let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .medium)
        let cancelImage = UIImage(systemName: "xmark", withConfiguration: symbolConfig)!
        button.setImage(cancelImage.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return button
    }()

    
    lazy var createPostMenuBar: CreatePostMenuBar = {
        let createPostMenuBar = CreatePostMenuBar()
        createPostMenuBar.delegate = self
        return createPostMenuBar
    }()
    
    
    let effectsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(effectsIcon?.withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()

           
   lazy var captureButton: UIButton = {
       let button = UIButton(type: .system)
       button.backgroundColor = UIColor.rgb(red: 254, green: 44, blue: 85)
       button.clipsToBounds = true
       button.layer.cornerRadius = captureButtonDimension / 2
       button.addTarget(self, action: #selector(handleDidTapRecordButton), for: .touchUpInside)
       return button
   }()
    
    fileprivate let captureButtonRingViewDimension : CGFloat = 85

    lazy var captureButtonRingView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.rgb(red: 254, green: 44, blue: 85).withAlphaComponent(0.5).cgColor
        view.layer.borderWidth = 6
        view.layer.cornerRadius = captureButtonRingViewDimension / 2
        view.clipsToBounds = true
//        view.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)
        view.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDidTapRecordButton))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
//
//    fileprivate let pulsingRingViewDimension : CGFloat = 125
//    lazy var pulsingRingView: UIView = {
//        let view = UIView()
//        view.layer.borderColor = UIColor.rgb(red: 254, green: 44, blue: 85).withAlphaComponent(0.5).cgColor
//        view.layer.borderWidth = 10
//        view.layer.cornerRadius = pulsingRingViewDimension / 2
//        view.isUserInteractionEnabled = true
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDidTapRecordButton))
//        view.addGestureRecognizer(tapGesture)
//        return view
//    }()

    
    
    lazy var discardRecordingButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setImage(discardIcon?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        button.addTarget(self, action: #selector(handleDidTapDiscardButton), for: .touchUpInside)
        return button
    }()
    
    
    fileprivate let saveRecordingButtonDimension: CGFloat = 35
    
    lazy var saveRecordingButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = tikTokRed
        button.tintColor = .white
        button.setImage(saveVideoCheckmarkIcon?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.layer.cornerRadius = saveRecordingButtonDimension / 2
        button.alpha = 0
        button.constrainHeight(constant: saveRecordingButtonDimension)
        button.constrainWidth(constant: saveRecordingButtonDimension)
        button.addTarget(self, action: #selector(handlePreviewCapturedVideo), for: .touchUpInside)
        return button
    }()
        
    
    let rightGuildeLineView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
//        view.backgroundColor = .red
        return view
    }()
    
    
    let leftGuildeLineView: UIView = {
       let view = UIView()
//       view.backgroundColor = .red
       return view
   }()
    
    
    lazy var openMediaPickerView: UIView = {
        let view = UIView()
//        view.backgroundColor = .red
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openOrCloseMediaPickerView))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
       return view
   }()

   lazy var openMediaPickerButton: UIButton = {
       let button = UIButton(type: .system)
       button.setImage(landscapeIcon?.withRenderingMode(.alwaysOriginal), for: .normal)
       button.addTarget(self, action: #selector(openOrCloseMediaPickerView), for: .allTouchEvents)
       return button
   }()
    
    
    let effectsLabel: UILabel = {
        let label = UILabel()
        label.text = "Effects"
        label.font = defaultFont(size: 12.5)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var uploadLabel: UILabel = {
        let label = UILabel()
        label.text = "Upload"
        label.font = defaultFont(size: 12.5)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openOrCloseMediaPickerView))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tapGesture)
        return label
    }()
    
    
    lazy var revertCameraDirectionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(flipCameraIcon, for: .normal)
        button.tintColor = .white
        button.constrainWidth(constant: buttonsDimension) //30
        button.constrainHeight(constant: buttonsDimension) //30
        button.addTarget(self, action: #selector(toggleCameraPosition), for: .touchUpInside)
        return button
    }()
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    let flipCameraLabel: UILabel = {
        let label = UILabel()
        label.text = "Flip"
        label.font = defaultFont(size: 10.5)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    
    let trimmedVideoNewLengthLabel: UILabelWithInsets = {
        let label = UILabelWithInsets()
        label.textInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
        label.textAlignment = .center
        label.textColor = .clear
        label.font = defaultFont(size: 14.5)//UIFont.boldSystemFont(ofSize: 15.5)
        label.clipsToBounds = true
        label.layer.cornerRadius = 30 / 2
//        label.text = "Sounds"
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let fullString = NSMutableAttributedString(string: "")
        // create our NSTextAttachment
        let image1Attachment = NSTextAttachment()
        image1Attachment.image = secondmusicIcon?.withRenderingMode(.alwaysOriginal)
        // wrap the attachment in its own attributed string so we can append it
        let image1String = NSAttributedString(attachment: image1Attachment)
        // add the NSTextAttachment wrapper to our full string, then add some more text.
        fullString.append(image1String)
        fullString.append(NSAttributedString(string: " Sounds"))
        // draw the result in a label
        label.attributedText = fullString
        return label
    }()
    
    
    
    
    
    lazy var videoSpeedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(speedIcon, for: .normal)
        button.tintColor = .white
        button.constrainWidth(constant: buttonsDimension)
        button.constrainHeight(constant: buttonsDimension)
//        button.addTarget(self, action: #selector(toggleCameraPosition), for: .touchUpInside)
        return button
    }()
    
    
    let videoSpeedLabel: UILabel = {
        let label = UILabel()
        label.text = "Speed"
        label.font = defaultFont(size: 10.5)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    
    
    lazy var beautyButton: UIButton = {
           let button = UIButton(type: .system)
           button.setImage(beautyIcon, for: .normal)
           button.tintColor = .white
           button.constrainWidth(constant: buttonsDimension)
           button.constrainHeight(constant: buttonsDimension)
   //        button.addTarget(self, action: #selector(toggleCameraPosition), for: .touchUpInside)
           return button
       }()
           
           
    let beautyLabel: UILabel = {
        let label = UILabel()
        label.text = "Beauty"
        label.font = defaultFont(size: 10.5)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    
    lazy var filtersButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(effectsIcon, for: .normal)
            button.tintColor = .white
            button.constrainWidth(constant: buttonsDimension)
            button.constrainHeight(constant: buttonsDimension)
    //        button.addTarget(self, action: #selector(toggleCameraPosition), for: .touchUpInside)
            return button
        }()
        
        
        let filtersLabel: UILabel = {
            let label = UILabel()
            label.text = "Filters"
            label.font = defaultFont(size: 10.5)
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
    
    
    
    lazy var countDownTimerButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(countDownTimerIcon, for: .normal)
            button.tintColor = .white
            button.constrainWidth(constant: buttonsDimension)
            button.constrainHeight(constant: buttonsDimension)
    //        button.addTarget(self, action: #selector(toggleCameraPosition), for: .touchUpInside)
            return button
        }()
        
        
        let countDownTimerLabel: UILabel = {
            let label = UILabel()
            label.text = "Timer"
            label.font = defaultFont(size: 10.5)
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
    
    
    
    lazy var flashButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(flashIcon, for: .normal)
            button.tintColor = .white
            button.constrainWidth(constant: buttonsDimension)
            button.constrainHeight(constant: buttonsDimension)
    //        button.addTarget(self, action: #selector(toggleCameraPosition), for: .touchUpInside)
            return button
        }()
        
        
        let flashLabel: UILabel = {
            let label = UILabel()
            label.text = "Flash"
            label.font = defaultFont(size: 10.5)
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
       
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

    
    fileprivate let recordingTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.text = "15"
        label.font = defaultFont(size: 11.5)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        label.textAlignment = .center
        label.clipsToBounds = true
        label.layer.cornerRadius = 30 / 2
        label.layer.borderWidth = 1.8
        label.layer.borderColor = UIColor.white.cgColor
        return label
       }()
       
        
    
    //MARK: - Handlers
    fileprivate func setUpViews() {
        view.addSubview(segmentedProgressView)
        segmentedProgressView.constrainToTop(paddingTop: 12)
        segmentedProgressView.centerXInSuperview()
        segmentedProgressView.constrainWidth(constant: view.frame.width - segmentedProgressViewPadding)
        segmentedProgressView.constrainHeight(constant: 6)
        
        
       
        
        view.addSubview(cancelButton)
        cancelButton.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 30, left: 12, bottom: 0, right: 0), size: .init(width: 30, height: 30))
        
        
        view.addSubview(recordingTimeLabel)
        recordingTimeLabel.anchor(top: cancelButton.bottomAnchor, leading: cancelButton.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 15, left: 0, bottom: 0, right: 0), size: .init(width: 30, height: 30))
        
        view.addSubview(createPostMenuBar)
        createPostMenuBar.anchor(top: nil, leading: nil, bottom: view.bottomAnchor, trailing: nil, size: .init(width: view.frame.width, height: 50))
        createPostMenuBar.centerXInSuperview()
        
        
        view.addSubview(captureButtonRingView)
         
        captureButtonRingView.anchor(top: nil, leading: nil, bottom: view.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 65, right: 0), size: .init(width: captureButtonRingViewDimension, height: captureButtonRingViewDimension))
         captureButtonRingView.centerXInSuperview()
         
         view.addSubview(captureButton)
         captureButton.centerXAnchor.constraint(equalTo: captureButtonRingView.centerXAnchor).isActive = true
         captureButton.centerYAnchor.constraint(equalTo: captureButtonRingView.centerYAnchor).isActive = true
         captureButton.constrainHeight(constant: captureButtonDimension)
         captureButton.constrainWidth(constant: captureButtonDimension)

 
        view.addSubview(rightGuildeLineView)
        rightGuildeLineView.anchor(top: captureButtonRingView.topAnchor, leading: captureButtonRingView.trailingAnchor, bottom: captureButtonRingView.bottomAnchor, trailing: view.trailingAnchor)
         
        view.addSubview(leftGuildeLineView)
        leftGuildeLineView.anchor(top: captureButtonRingView.topAnchor, leading: view.leadingAnchor, bottom: captureButtonRingView.bottomAnchor, trailing: captureButtonRingView.leadingAnchor)
         
         rightGuildeLineView.addSubview(openMediaPickerButton)
         openMediaPickerButton.centerInSuperview()

        view.addSubview(openMediaPickerView)
        openMediaPickerView.centerYAnchor.constraint(equalTo: openMediaPickerButton.centerYAnchor).isActive = true
        openMediaPickerView.centerXAnchor.constraint(equalTo: openMediaPickerButton.centerXAnchor).isActive = true

        openMediaPickerView.constrainHeight(constant: 70)
        openMediaPickerView.constrainWidth(constant: 60)

         
         leftGuildeLineView.addSubview(effectsButton)
         effectsButton.centerInSuperview()
         
         rightGuildeLineView.addSubview(uploadLabel)
         uploadLabel.topAnchor.constraint(equalTo: openMediaPickerButton.bottomAnchor, constant: 2.5).isActive = true
         uploadLabel.centerXAnchor.constraint(equalTo: openMediaPickerButton.centerXAnchor).isActive = true

         
         
        leftGuildeLineView.addSubview(effectsLabel)
         effectsLabel.topAnchor.constraint(equalTo: effectsButton.bottomAnchor, constant: 2.5).isActive = true
        effectsLabel.centerXAnchor.constraint(equalTo: effectsButton.centerXAnchor).isActive = true
        
        
        
        

        ////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        
        view.addSubview(trimmedVideoNewLengthLabel)
        trimmedVideoNewLengthLabel.anchor(top: segmentedProgressView.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 15, left: 0, bottom: 0, right: 0), size: .init(width: 0, height: 30))
        trimmedVideoNewLengthLabel.centerXInSuperview()
        
        
        
        view.addSubview(revertCameraDirectionButton)
        revertCameraDirectionButton.anchor(top: cancelButton.topAnchor, leading: nil, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 12))
        
        
       
        view.addSubview(flipCameraLabel)
        flipCameraLabel.topAnchor.constraint(equalTo: revertCameraDirectionButton.bottomAnchor, constant: 4).isActive = true
        flipCameraLabel.centerXAnchor.constraint(equalTo: revertCameraDirectionButton.centerXAnchor).isActive = true
        
        
        view.addSubview(videoSpeedButton)
        videoSpeedButton.anchor(top: revertCameraDirectionButton.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 35, left: 0, bottom: 0, right: 0), size: .init(width: buttonsDimension, height: buttonsDimension))
        videoSpeedButton.centerXAnchor.constraint(equalTo: (revertCameraDirectionButton).centerXAnchor).isActive = true

               
            
        view.addSubview(videoSpeedLabel)
        videoSpeedLabel.topAnchor.constraint(equalTo: (videoSpeedButton).bottomAnchor, constant: 4).isActive = true
        videoSpeedLabel.centerXAnchor.constraint(equalTo: (videoSpeedButton).centerXAnchor).isActive = true
        
               

        
        view.addSubview(beautyButton)
        beautyButton.anchor(top: videoSpeedButton.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 38, left: 0, bottom: 0, right: buttonsRightPadding), size: .init(width: buttonsDimension, height: buttonsDimension))
        beautyButton.centerXAnchor.constraint(equalTo: (revertCameraDirectionButton).centerXAnchor).isActive = true
        
        
        view.addSubview(beautyLabel)
        beautyLabel.topAnchor.constraint(equalTo: (beautyButton).bottomAnchor, constant: 4).isActive = true
        beautyLabel.centerXAnchor.constraint(equalTo: (beautyButton).centerXAnchor).isActive = true
        

        
        
        
        view.addSubview(filtersButton)
       filtersButton.anchor(top: beautyButton.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 38, left: 0, bottom: 0, right: buttonsRightPadding), size: .init(width: buttonsDimension, height: buttonsDimension))
       filtersButton.centerXAnchor.constraint(equalTo: (revertCameraDirectionButton).centerXAnchor).isActive = true
       
       
       view.addSubview(filtersLabel)
       filtersLabel.topAnchor.constraint(equalTo: (filtersButton).bottomAnchor, constant: 4).isActive = true
       filtersLabel.centerXAnchor.constraint(equalTo: (filtersButton).centerXAnchor).isActive = true
               
        
        
        view.addSubview(countDownTimerButton)
        countDownTimerButton.anchor(top: filtersButton.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 38, left: 0, bottom: 0, right: buttonsRightPadding), size: .init(width: buttonsDimension, height: buttonsDimension))
        countDownTimerButton.centerXAnchor.constraint(equalTo: (revertCameraDirectionButton).centerXAnchor).isActive = true
             
             
             view.addSubview(countDownTimerLabel)
             countDownTimerLabel.topAnchor.constraint(equalTo: (countDownTimerButton).bottomAnchor, constant: 4).isActive = true
             countDownTimerLabel.centerXAnchor.constraint(equalTo: (countDownTimerButton).centerXAnchor).isActive = true
                     
               
        
        
        view.addSubview(flashButton)
       flashButton.anchor(top: countDownTimerButton.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 38, left: 0, bottom: 0, right: buttonsRightPadding), size: .init(width: buttonsDimension, height: buttonsDimension))
       flashButton.centerXAnchor.constraint(equalTo: (revertCameraDirectionButton).centerXAnchor).isActive = true
            
            
            view.addSubview(flashLabel)
            flashLabel.topAnchor.constraint(equalTo: (flashButton).bottomAnchor, constant: 4).isActive = true
            flashLabel.centerXAnchor.constraint(equalTo: (flashButton).centerXAnchor).isActive = true
                    
                      
        
        
        
        
        
        ////////////////////////////////////////////////////////////////////////////////////////////////////////

            
        
        let save_discardButtonsStacView = UIStackView(arrangedSubviews: [discardRecordingButton, saveRecordingButton])
        save_discardButtonsStacView.axis = .horizontal
        save_discardButtonsStacView.distribution = .fillEqually
        rightGuildeLineView.addSubview(save_discardButtonsStacView)
        save_discardButtonsStacView.constrainHeight(constant: saveRecordingButtonDimension)
        save_discardButtonsStacView.constrainWidth(constant: 100)
        save_discardButtonsStacView.centerInSuperview()
        
        
        handleSetUpDevices()
        
        if setUpSession() {
            perform(#selector(startSession), with: nil, afterDelay: 0.3)
        }
        
        handleSetUpMediaPicker()
        
    }
    
   
    //MARK: - Finish this 
    fileprivate func handleSetUpMediaPicker() {
        view.addSubview(mediaPickerView)
        mediaPickerView.anchor(top: nil, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, size: .init(width: 0, height: MediaPickerView.MediaPickerHeight))
        mediaPickerView.transform = CGAffineTransform(translationX: 0, y: MediaPickerView.MediaPickerHeight)
        mediaPickerView.mediaPickerWasClosedDelegate = self
       
    }
    
    @objc fileprivate func openOrCloseMediaPickerView() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn) {[weak self] in
            guard let self = self else {return}
            if self.isMediaPickerOpen == false {
                self.mediaPickerView.transform = .identity
                self.stopSession()
            } else {
                self.mediaPickerView.transform = .init(translationX: 0, y: MediaPickerView.MediaPickerHeight)
            }
        } completion: {[weak self] (onComplete) in
            guard let self = self else {return}
            self.isMediaPickerOpen = !self.isMediaPickerOpen
        }
    }
    

    
    @objc fileprivate func handleDidTapDiscardButton() {
        let alertVC = UIAlertController(title: "Discard the last clip?", message: nil, preferredStyle: .alert)
        let discardAction = UIAlertAction(title: "Discard", style: .default) {[weak self] (_) in
//            print("handleDidTapDiscardButton:", "Discard")
            self?.handleDiscardLastRecordedClip()
        }
        let keepAction = UIAlertAction(title: "Keep", style: .cancel) { (_) in
//            print("handleDidTapDiscardButton:", "Keep")
        }
        alertVC.addAction(discardAction)
        alertVC.addAction(keepAction)
        present(alertVC, animated: true, completion: nil)
    }
    
    
    
    @objc fileprivate func handleDiscardLastRecordedClip() {
//        FileManager.default.clearTmpDirectory()
        outPutURL = nil //remove current clip url that was juast discarded
        thumbnailImage = nil //remove current thumbnail image
        recordedClips.removeLast() //remove discarded clip from clips array
        handleSetNewOutPutURLAndThumbnailImage()
        segmentedProgressView.handleRemoveLastSegment()
        handleResetAllVisibilityToIdentity()
        maxVidDurationExhasuted = false
        if recordedClips.isEmpty == true {
            handleResetTimersAndProgressViewToZero()
        } else if recordedClips.isEmpty == false {
            handleCalculateDurationLeft()
        }
    }
    
    
    @objc fileprivate func handleSetNewOutPutURLAndThumbnailImage() {
        outPutURL = recordedClips.last?.videoUrl
        let currentUrl: URL? = outPutURL
        guard let currentUrlUnwrapped = currentUrl else {return}
        guard let generatedThumbnailImage = generateVideoThumbnail(withfile: currentUrlUnwrapped) else {return}
        if currentCameraDevice?.position == .front {
            //if front camera we mirror the thumbnail image, else keep the same orientation the same
            thumbnailImage = didTakePicture(generatedThumbnailImage, to: .upMirrored)
        } else {
            thumbnailImage = generatedThumbnailImage
        }
    }
    
    /// this subtracts the discarded clip's duration from the currentTime duration of our video
    fileprivate func handleCalculateDurationLeft() {
        let timeToDiscard = videoDurationOfLastClip
        let currentCombineTime = total_RecordedTime_In_Secs
        let newVideoDuration = currentCombineTime - timeToDiscard
        total_RecordedTime_In_Secs = newVideoDuration
        let countDownSec: Int = Int(currentMaxRecordingDuration)  - total_RecordedTime_In_Secs / 10
        recordingTimeLabel.text = "\(countDownSec)s"
    }
    
    @objc func handleResetAllVisibilityToIdentity() {
        if recordedClips.isEmpty == true {
            openMediaPickerButton.isHidden = false
            openMediaPickerView.isHidden = false
            uploadLabel.isHidden = false
            createPostMenuBar.isHidden = false
            discardRecordingButton.alpha = 0
            saveRecordingButton.alpha = 0
            print("recordedClips:", "isEmpty")
        } else {
            openMediaPickerButton.isHidden = true
            openMediaPickerView.isHidden = true
            uploadLabel.isHidden = true
            createPostMenuBar.isHidden = true
            discardRecordingButton.alpha = 1
            saveRecordingButton.alpha = 1
            print("recordedClips:", "is not Empty")

        }
        
        
        [self.effectsLabel, self.effectsButton, self.revertCameraDirectionButton, self.cancelButton].forEach { (subView) in
            subView.isHidden = false
        }
        
        if setUpSession() {
            perform(#selector(startSession), with: nil, afterDelay: 0.1)
        }
    }
    
    
    @objc fileprivate func handleDismiss() {
        FileManager.default.clearTmpDirectory()
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
    
    @objc fileprivate func handlePreviewCapturedVideo() {
        if let thumbnailImageUnwrapped = thumbnailImage, let cameraPosition = currentCameraDevice?.position {
            let previewVC = PreviewCapturedVideoVC(recordedClips: recordedClips)
            previewVC.viewWillDenitRestartVideoSession = {[weak self] in
                guard let self = self else {return}
                if self.setUpSession() {
                    self.perform(#selector(self.startSession), with: nil, afterDelay: 0.1)
                }
            }
            navigationController?.pushViewController(previewVC, animated: true)
        }
    }
    
    
    @objc fileprivate func handleDidTapRecordButton() {
        if movieOutput.isRecording == false {
            if maxVidDurationExhasuted == false {
                startRecording()
            } else {
//                SVProgressHUD.show(withStatus: "You cant record more")
//                SVProgressHUD.dismiss(withDelay: 1.0)
            }
        } else {
            stopRecording()
        }

    }
    
    
    
 
    
    var isRecording = false
    fileprivate func handleAnimateRecordButton() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {[weak self] in
             guard let self = self else {return}
             if self.isRecording == false {
               self.captureButton.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
               self.captureButton.layer.cornerRadius = 5
               self.captureButtonRingView.transform = CGAffineTransform(scaleX: 1.7, y: 1.7)
                
                self.saveRecordingButton.alpha = 0
                self.discardRecordingButton.alpha = 0

                [self.createPostMenuBar, self.effectsLabel, self.effectsButton, self.uploadLabel, self.openMediaPickerButton, self.openMediaPickerView, self.revertCameraDirectionButton, self.cancelButton].forEach { (subView) in
                    subView.isHidden = true
                }

             } else {
                
               self.captureButton.transform = CGAffineTransform.identity
               self.captureButton.layer.cornerRadius = self.captureButtonDimension / 2
               self.captureButtonRingView.transform = CGAffineTransform.identity
                
                self.handleResetAllVisibilityToIdentity()
//               self.discardRecordingButton.alpha = 1
//
//               [self.createPostMenuBar, self.effectsLabel, self.effectsButton, self.revertCameraDirectionButton, self.cancelButton].forEach { (subView) in
//                    subView.isHidden = false
//                }
             }
        }) {[weak self] (onComplete) in
            guard let self = self else {return}
            self.isRecording = !self.isRecording
        }
      }
    
    
    @objc func toggleCameraPosition() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {[weak self] in
            self?.revertCameraDirectionButton.flipX()
        })
        
          captureSession.beginConfiguration()
          guard let newDevice = (currentCameraDevice?.position == .back) ? frontFacingCamera : backFacingCamera else {return}
          
          //1. Remove all current inputs in capture session
          for input in captureSession.inputs {
              captureSession.removeInput(input as! AVCaptureDeviceInput)
          }
          
          
          //2. SetUp Camera
          do {
              let input = try AVCaptureDeviceInput(device: newDevice)
              if captureSession.canAddInput(input) {
                  captureSession.addInput(input)
                  activeInput = input
                  
              }
              
              
          } catch let inputError {
              print("Error setting device video input\(inputError)")
          }
          
          
          //3. Set up mic
          if let microphone = AVCaptureDevice.default(for: .audio) {
              
              do {
                  let micInput = try AVCaptureDeviceInput(device: microphone)
                  if captureSession.canAddInput(micInput) {
                      captureSession.addInput(micInput)
                      
                  }
                  
              } catch let micInputError {
                  print("Error setting device audio input\(micInputError)")
              }
          }
          
          
          
          currentCameraDevice = newDevice
          captureSession.commitConfiguration()
          
      }
    
    
    //MARK: - Code Was Created by SamiSays11. Copyright © 2019 SamiSays11 All rights reserved.
}



extension CreatePostVC: AVCaptureFileOutputRecordingDelegate {
   
    //MARK: - SetUp Session
       func setUpSession() -> Bool {
           
           captureSession.sessionPreset = AVCaptureSession.Preset.high
           
           
           //1. SetUp Camera
           if let currentCameraUnwrapped = currentCameraDevice {
               do {
                   let input = try AVCaptureDeviceInput(device: currentCameraUnwrapped)
                   if captureSession.canAddInput(input) {
                       captureSession.addInput(input)
                       activeInput = input
                       
                   }
                   
               } catch let inputError {
                   print("Error setting device video input\(inputError)")
                   return false
               }
               
           }
           
           
           //2. Set up mic
           if let microphone = AVCaptureDevice.default(for: .audio) {
               
               do {
                   let micInput = try AVCaptureDeviceInput(device: microphone)
                   if captureSession.canAddInput(micInput) {
                       captureSession.addInput(micInput)
                       
                   }
                   
               } catch let micInputError {
                   print("Error setting device audio input\(micInputError)")
                   return false
               }
           }
           
           
           
           //3. Movie Recorded OutPut
           if captureSession.canAddOutput(movieOutput) {
               captureSession.addOutput(movieOutput)
           }
           
           
           //3. Photo Captured Output
           if captureSession.canAddOutput(photoOutput) {
               photoOutput.isHighResolutionCaptureEnabled = true
               captureSession.addOutput(photoOutput)
           }

           
           //4. setup output preview
           //        previewLayer.isHidden = true

           
           previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
           previewLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
           view.layer.insertSublayer(previewLayer, below: segmentedProgressView.layer)
           return true
       }
    
    
    
    
    func handleSetUpDevices() {
        //only builtInWideAngleCamera worked so i had to add mic seperately
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [ .builtInMicrophone, .builtInWideAngleCamera, .builtInDualCamera, .builtInTelephotoCamera ], mediaType: .video, position: .unspecified).devices
        
        for device in devices {
            if device.position == .back {
                backFacingCamera = device
            } else if device.position == .front {
                frontFacingCamera = device
                
            }
        }
        
        //default
        currentCameraDevice = backFacingCamera
        
    }
    
    
    
    
    //MARK:- Camera Session
       @objc func startSession() {
           
           if !captureSession.isRunning {
               videoQueue().async {
                   self.captureSession.startRunning()
               }
           }
       }
       
       
       
       func stopSession() {
           if captureSession.isRunning {
               videoQueue().async {
                   self.captureSession.stopRunning()
               }
           }
       }
       
       
       
       func videoQueue() -> DispatchQueue {
           return DispatchQueue.main
           
       }
    
    
    
    func tempURL() -> URL? {
           let directory = NSTemporaryDirectory() as NSString
           
           if directory != "" {
               let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
               return URL(fileURLWithPath: path)
           }
           
           return nil
       }
    
    
    
    func startRecording() {
        if movieOutput.isRecording == false {
            guard let connection = movieOutput.connection(with: .video) else {return}
            if (connection.isVideoOrientationSupported) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
                
                let device = activeInput.device
                if (device.isSmoothAutoFocusSupported) {
                    do {
                        try device.lockForConfiguration()
                        device.isSmoothAutoFocusEnabled = false
                        device.unlockForConfiguration()
                    } catch {
                        print("Error setting configuration: \(error)")
                    }
                    
                }
                
                outPutURL = tempURL()
                movieOutput.startRecording(to: outPutURL, recordingDelegate: self)
                handleAnimateRecordButton()
//                segmentedProgressView.setProgress(0)

            }
        }
//        else {
//            stopRecording()
//        }
    }
    
    
    func stopRecording() {
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
            stopTimer()
            saveRecordingButton.alpha = 1
            segmentedProgressView.pauseProgress()
            handleAnimateRecordButton()
            print("STOP THE COUNT!!!")
        }
    }
    
    
    
    //MARK: - AVCaptureFileOutputRecordingDelegate
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        //
        let newRecordedClip = VideoClips(videoUrl: fileURL, cameraPosition: currentCameraDevice?.position)
        recordedClips.append(newRecordedClip)
        print("recordedClips:", recordedClips.count)
        startTimer()
        
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if (error != nil) {
            print("Error recording movie: \(error?.localizedDescription ?? "")")
        } else {
            ///at this point we do not have access to the phhasset yet because its yet to be created, however we do have access to the temp url and we can generate a thumbnail from that using AVAssetImageGenerator. we generate the real asset to be exported to DB later in the mediaPreviewView itsself upon setting the URL setter
            let urlOfVideoRecorded = outPutURL! as URL

            guard let generatedThumbnailImage = generateVideoThumbnail(withfile: urlOfVideoRecorded) else {return}
            if currentCameraDevice?.position == .front {
                //if front camera we mirror the thumbnail image, else keep the same orientation the same
                thumbnailImage = didTakePicture(generatedThumbnailImage, to: .upMirrored)
            } else {
                thumbnailImage = generatedThumbnailImage
            }
        }
    }
       
    
    
    
    
    
    ////MARK: - Recording Timer
    fileprivate func startTimer(){
        // if you want the timer to reset to 0 every time the user presses record you can uncomment out either of these 2 lines
        
//         timeSec = 0
        // timeMin = 0
        
        videoDurationOfLastClip = 0
  
        stopTimer() // stop it at it's current time before starting it again
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }
    
    
    
    
    
    @objc fileprivate func timerTick(){
        total_RecordedTime_In_Secs += 1
        videoDurationOfLastClip += 1
        
       let time_limit = currentMaxRecordingDuration * 10
       if total_RecordedTime_In_Secs == time_limit {
           handleDidTapRecordButton()
           maxVidDurationExhasuted = true
        
       }
       let startTime = 0
       let trimmedTime: Int = Int(currentMaxRecordingDuration)  - startTime
       let positiveOrZero = max(total_RecordedTime_In_Secs, 0) //makes sure it doesnt go below 0 i.e no negative readings
       let progress = Float(positiveOrZero) / Float(trimmedTime) / 10
        segmentedProgressView.setProgress(CGFloat(progress))
        let countDownSec: Int = Int(currentMaxRecordingDuration)  - total_RecordedTime_In_Secs / 10
        recordingTimeLabel.text = "\(countDownSec)s"
    }
    
    
    // resets both vars back to 0 and when the timer starts again it will start at 0
    @objc fileprivate func handleResetTimersAndProgressViewToZero(){
        total_RecordedTime_In_Secs = 0
        totalRecordedTime_In_Minutes = 0
        videoDurationOfLastClip = 0
        stopTimer()
        segmentedProgressView.setProgress(0)
        recordingTimeLabel.text = "\(currentMaxRecordingDuration)s"

    }

    // stops the timer at it's current time
    @objc  func stopTimer(){
        recordingTimer?.invalidate()
    }
       
}



//MARK: - MediaPickerWasClosedDelegate
extension CreatePostVC: MediaPickerWasClosedDelegate {
    func didTapCloseMediaPicker() {
        openOrCloseMediaPickerView()
        if setUpSession() {
            perform(#selector(startSession), with: nil, afterDelay: 0.1)
        }
    }
    
    
    
    
    func didTapNextButton(selectedAssets: [PHAsset]) {
        if selectedAssets.count == 1 {
            prepareToLoadVideoUrlIntoPlayer(selectedAssets.first!) {[weak self] (videoURL, avasset) in
                let trimVideoVC = TrimVideoVC(videoURL: videoURL, asset: avasset)
                self?.navigationController?.pushViewController(trimVideoVC, animated: true)
                self?.handleChangeMediaView(alpha: 0)

            }
        } else {
            var selectedVideoMediaList = [SelectedVideoMedia]()
            for (index, asset) in selectedAssets.enumerated() {
                prepareToLoadVideoUrlIntoPlayer(asset) {[weak self] (videoURL, avAsset) in
                    let selectedMedia = SelectedVideoMedia.init(videoUrl: videoURL, avAsset: avAsset)
                    selectedVideoMediaList.append(selectedMedia)
                    if index == selectedAssets.count - 1 {
                        let syncVideoVC = SyncVideosVC(selectedVideoMedia: selectedVideoMediaList)
                        self?.navigationController?.pushViewController(syncVideoVC, animated: true)
                        self?.handleChangeMediaView(alpha: 0)
                    }
                }
                
            }
        }
    }
    
    fileprivate func handleChangeMediaView(alpha: CGFloat) {
        view.alpha = alpha
        mediaPickerView.alpha = alpha
    }
    
    fileprivate func prepareToLoadVideoUrlIntoPlayer(_ asset: PHAsset, onComplete: @escaping (URL, AVAsset) -> ()) {
        if asset.mediaType == .video {
            asset.getURL { (url, image, avasset) in
                DispatchQueue.main.async {
                    if let urlUnwrapped = url, let avasset = avasset  {
                        onComplete(urlUnwrapped, avasset)
                    }
                }
            }
        } else if asset.mediaType == .image {
            
        }
    }
    
}


//MARK: - CreatePostMenuBarDelegate
extension CreatePostVC : CreatePostMenuBarDelegate {
    
    
    func didSelectMenu(at index: Int) {
        if index == 0 {
            currentMaxRecordingDuration = 60
            print("currentMaxRecordingDuration:", currentMaxRecordingDuration)
        } else if index == 1 {
            currentMaxRecordingDuration = 15
            print("currentMaxRecordingDuration:", currentMaxRecordingDuration)

        } else if index == 2 {
            //open templates
            print("currentMaxRecordingDuration:", "open temlates")

        }
    }
    
}
