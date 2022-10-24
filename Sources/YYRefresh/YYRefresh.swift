import SwiftUI
import Lottie

// MARK: - Configuration
public struct YYRefreshConfiguration {
    public var lottieFileName:String = "Loading"
    public var showScrollIndicator:Bool = false
    // SF Symbol Name
    public var refreshIndicator:String = "arrow.down"
    public var maxHeight:CGFloat = 150
    public var pull_to_refresh = "Pull To Refresh"
    public var release_to_refresh = "Release To Refresh"
}

// MARK: - YYRefresh
public struct YYRefresh<Content:View>: View {
    
    var config:YYRefreshConfiguration = .init()
    var content:Content
    var onRefrsh:()async->()
    
    public init(config:YYRefreshConfiguration = .init(),@ViewBuilder content:@escaping ()->Content, onRefrsh: @escaping ()async -> ()) {
        self.config = config
        self.content = content()
        self.onRefrsh = onRefrsh
    }
    
    
    @StateObject var scrollDelegate:YYScrollViewModel = .init()
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: showIndicator) {
            VStack(spacing: 0) {
                YYLottieView(isPlaying: $scrollDelegate.isRefreshing)
                    .scaleEffect(scrollDelegate.isEligible ? 1 : 0.001)
                    .animation(.easeInOut(duration: 0.2), value: scrollDelegate.isEligible)
                // MARK: - Arrow & Text
                    .overlay(content: {
                        VStack(spacing: 12) {
                            Image(systemName: self.config.refreshIndicator)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(scrollDelegate.progress * 180))
                                .padding(8)
                                .background(.primary, in: Circle())
                            
                            Text(scrollDelegate.progress == 1 ? self.config.release_to_refresh : self.config.pull_to_refresh)
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                        }
                        .opacity(scrollDelegate.isEligible ? 0 : 1)
                        .animation(.easeInOut(duration: 0.25), value: scrollDelegate.isEligible)
                    })
                    .frame(height: scrollDelegate.progress * 150)
                    .opacity(scrollDelegate.progress)
                    .offset(y: scrollDelegate.isEligible ? -(scrollDelegate.contentOffset < 0 ? 0 : scrollDelegate.contentOffset) : -(scrollDelegate.scrollOffset < 0 ? 0 : scrollDelegate.scrollOffset))
                content
            }
            .yy_offsetY(coordinateSpace: "SCROLL") { offsetY in
                
                scrollDelegate.contentOffset = offsetY
                
                if !scrollDelegate.isEligible {
                    var progress = offsetY / 150
                    progress = progress < 0 ? 0 : progress
                    progress = progress > 1 ? 1 : progress
                    scrollDelegate.scrollOffset = offsetY
                    scrollDelegate.progress = progress
                }
                
                //
                if scrollDelegate.isEligible && !scrollDelegate.isRefreshing {
                    scrollDelegate.isRefreshing = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
        .coordinateSpace(name: "SCROLL")
        .onAppear(perform: scrollDelegate.addGesture)
        .onDisappear(perform: scrollDelegate.removeGesture)
        .onChange(of: scrollDelegate.isRefreshing) { newValue in
            // MARK: - Begin Async Refresh
            if newValue {
                Task {
                    await onRefrsh()
                    
                    // after done reset the properties
                    withAnimation(.easeOut(duration: 0.25)) {
                        scrollDelegate.progress = 0
                        scrollDelegate.isRefreshing = false
                        scrollDelegate.isEligible = false
                        scrollDelegate.scrollOffset = 0
                    }
                }
            }
        }
    }
}

// MARK: - For Simultanenous Pan Gesture
class YYScrollViewModel:NSObject,ObservableObject,UIGestureRecognizerDelegate {
    
    @Published var isEligible:Bool = false
    @Published var isRefreshing:Bool = false
    // offset & progress
    // MARK: - Storing offset just when offset is less than 150
    @Published var scrollOffset:CGFloat = 0
    // MARK: - Storing offset with no limit
    @Published var contentOffset:CGFloat = 0
    // from 0-1
    @Published var progress:CGFloat = 0
    
    var config:YYRefreshConfiguration = .init()
    
    init(config:YYRefreshConfiguration) {
        self.config = config
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // add gesture
    func addGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onGestureChange(gesture:)))
        panGesture.delegate = self
        
        rootController().view.addGestureRecognizer(panGesture)
    }
    // remove gesture
    func removeGesture() {
        rootController().view.gestureRecognizers?.removeAll()
    }
    
    func rootController() -> UIViewController {
        guard let scence = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return .init() }
        guard let root = scence.windows.first?.rootViewController else { return .init() }
        return root
    }
    
    @objc
    func onGestureChange(gesture:UIPanGestureRecognizer) {
        if gesture.state == .cancelled || gesture.state == .ended {
            // limit progress
            if !isRefreshing {
                if scrollOffset > self.config.maxHeight {
                    self.isEligible = true
                }else {
                    self.isEligible = false
                }
            }
        }
    }
}

// MARK: - Offset Modifier
extension View {
    @ViewBuilder
    func yy_offsetY(coordinateSpace:String,offset:@escaping(CGFloat)->()) -> some View {
        self
            .overlay {
                GeometryReader { proxy in
                    let minY = proxy.frame(in: .named(coordinateSpace)).minY
                    Color.clear
                        .preference(key: YYOffsetYKey.self, value: minY)
                        .onPreferenceChange(YYOffsetYKey.self) { value in
                            offset(value)
                        }
                }
            }
    }
}

// MARK: - OffsetKey
struct YYOffsetYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Lottie
struct YYLottieView: UIViewRepresentable {
    
    // Replace your lottie fileName
    var fileName:String
    @Binding var isPlaying:Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        addLottie(to: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let view = uiView.subviews.first,let lottie = view as? LottieAnimationView {
            if lottie.tag == 99 {
                if isPlaying {
                    lottie.play()
                }else {
                    lottie.pause()
                }
            }
        }
    }
    
    func addLottie(to view:UIView) {
        let lottie = LottieAnimationView(name: fileName)
        lottie.backgroundColor = .clear
        lottie.translatesAutoresizingMaskIntoConstraints = false
        lottie.tag = 99
        
        let constraints = [
            lottie.widthAnchor.constraint(equalTo: view.widthAnchor),
            lottie.heightAnchor.constraint(equalTo: view.heightAnchor)
        ]
        
        view.addSubview(lottie)
        view.addConstraints(constraints)
    }
}

