//
//  ImageViewController.swift
//  Cassini
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController
{
    // наша Model
    // устанавливается извне (publicly)
    // если она меняется (но только если мы на экране)
    //   делаем выборку image по imageURL
    // если мы не на экране, когда это происходит (view.window == nil)
    //   viewWillAppear будет делать это за нас позже
    var imageURL: URL? {
        didSet {
            image = nil
            if view.window != nil {
                fetchImage()
            }
        }
    }
    
    // выбираем image по imageURL
    // делаем это за пределами main thread
    // затем создаем блок, возвращающий нас в main queue
    //   для размещения image на UI
    //   (так как нам не разрешено что-то делать с UI где-то еще, кроме main queue)
    private func fetchImage() {
        autoZoomed = true
        if let url = imageURL {
            spinner?.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let contentsOfURL = try? Data(contentsOf: url)
                // делаем что-то с этим image только в том случае
                // если url, которое мы выбрали является текущим imageURL
                // (он может измениться, пока мы выбирали его)
                if let imageData = contentsOfURL, url == self?.imageURL {
                    DispatchQueue.main.async {
                        self?.image = UIImage(data: imageData)
                    }
                }
            }
        }
    }
    
  
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var scrollView: UIScrollView! {
        didSet {
            scrollView.contentSize = imageView.frame.size // critical to set this!
            scrollView.delegate = self                    // обязателен для zooming
            scrollView.minimumZoomScale = 0.03            // обязателен для zooming
            scrollView.maximumZoomScale = 5.0             // обязателен для zooming
            scrollView.addSubview(imageView)
        }
    }
    
    fileprivate var imageView = UIImageView()
    fileprivate var autoZoomed = true
    
    // удобное вычисляемое свойство
    // это свойство "работает" всякий раз,когда мы устанавливаем image в imageView
    // мы можем делать такие вещи, как изменение размера imageView,
    //   установка свойства contentSize для scrollView
    //   и остановка spinner
   var image: UIImage? {
        get { return imageView.image }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating()
            autoZoomed = true
            zoomScaleToFit()

        }
    }
    
    // для эффективности мы будем осуществлять актуальную выборку image
    // когда мы точно знаем, что появимся на экране
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            fetchImage()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        zoomScaleToFit()
    }

    @IBAction func toRootViewController(_ sender: UIBarButtonItem) {
    _ = navigationController?.popToRootViewController(animated: true)
    }
    
    // Рассчитывает zoom масштаб для "подгонки" изображения к размеру экрана,
    // но без пустых (белых) зазоров
    private func zoomScaleToFit()
    {
    // если мы все еще в режиме "подгонки" (autoZoomed), то устанавливаем 
    // свойство zoomScale только при условии, что геометрия полностью загружена
        if !autoZoomed {
            return
        }
        if let sv = scrollView , image != nil && (imageView.bounds.size.width > 0)
                                                  && (scrollView.bounds.size.width > 0){
           
                let widthRatio = scrollView.bounds.size.width  / imageView.bounds.size.width
                let heightRatio = scrollView.bounds.size.height / self.imageView.bounds.size.height
                sv.zoomScale = (widthRatio > heightRatio) ? widthRatio : heightRatio
                sv.contentOffset = CGPoint(x: (imageView.frame.size.width - sv.frame.size.width) / 2,
                                           y: (imageView.frame.size.height - sv.frame.size.height) / 2)
        }
    }
}

// MARK: UIScrollViewDelegate
// Extension заставляет ImageViewController подтверждать UIScrollViewDelegate
// Управляем viewForZooming(in scrollView:) возвращая UIImageView,
// которое будет трансформироваться при zooming

extension ImageViewController : UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // Убираем автоматическую "подгонку" после того, как пользователь выполняет zoom
    // с помощью жеста pinching
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        autoZoomed = false
    }
}
