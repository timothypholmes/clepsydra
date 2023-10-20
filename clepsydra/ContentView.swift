import AVFoundation
import Combine
import SwiftUI

var player: AVAudioPlayer?

struct VisualEffectView: NSViewRepresentable {
  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()

    view.blendingMode = .behindWindow
    view.state = .active
    view.material = .underWindowBackground

    return view
  }

  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    //
  }
}

struct BarSlider: Shape {
  var values: [CGFloat] = Array(repeating: 1, count: 60)
  @Binding var sliderPosition: CGFloat  // Add a binding to the slider position

  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: rect.origin)
    for (index, value) in values.enumerated() {
      let padding = rect.height * (1 - value) * 0.1
      let barWidth: CGFloat = 0.05
      let spacing = 0.25
      let barRect = CGRect(
        x: (CGFloat(barWidth) + spacing) * CGFloat(index),
        y: rect.origin.y + padding * 0.5,
        width: barWidth,
        height: rect.height - padding
      )
      path.addRoundedRect(in: barRect, cornerSize: CGSize(width: 1, height: 0.1))
    }
    let bounds = path.boundingRect
    let scaleX = rect.size.width / bounds.size.width
    let scaleY = rect.size.height / bounds.size.height

    return path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
  }
}

struct SliderRectangle: View {
  @Binding var position: CGFloat
  let width: CGFloat
  let color: Color
  var totalDuration: Double
  @Binding var remainingTime: Double

  @GestureState private var isDragging = false
  @GestureState private var tapLocation: CGPoint?

  private func calculateSliderPosition() -> CGFloat {
    let ratio = CGFloat(remainingTime / totalDuration)
    return ratio * width
  }

  var body: some View {
    Rectangle()
      .fill(color)
      .frame(width: 2.5, height: isDragging ? 62 : 56)  // Adjust the
      .position(x: calculateSliderPosition(), y: 28)
      .gesture(
        DragGesture()
          .onChanged { gesture in
            let newPosition = min(max(gesture.location.x, 0), self.width)
            let percentage = Double(newPosition / self.width)
            self.remainingTime = self.totalDuration * percentage
            self.position = newPosition
          }
          .updating($isDragging) { value, state, transaction in
            state = true
          }
      )
      .animation(.easeInOut(duration: 0.2))
  }
}

struct SliderView: View {
  @State private var sliderPosition: CGFloat = 0.0
  var sliderColor: Color  // Color binding
  var totalDuration: Double
  @Binding var remainingTime: Double

  var body: some View {
    GeometryReader { geometry in
      VStack {
        BarSlider(sliderPosition: $sliderPosition)  // Pass sliderPosition to MagnitudeChart
          .fill(Color.gray.opacity(0.5))
          .background(Color.gray.opacity(0))  // Background color for the chart
          .gesture(
            DragGesture(minimumDistance: 0)  // Add minimumDistance to allow clicking
              .onChanged { gesture in
                let newPosition = min(max(gesture.location.x, 0), geometry.size.width)
                self.sliderPosition = newPosition

                let percentage = Double(newPosition / geometry.size.width)
                self.remainingTime = self.totalDuration * percentage
              }
          )
          .overlay(
            SliderRectangle(
              position: $sliderPosition,
              width: geometry.size.width,
              color: sliderColor,
              totalDuration: totalDuration,  // Pass totalDuration to SliderRectangle
              remainingTime: $remainingTime  // Pass remainingTime to SliderRectangle
            )
          )
      }
    }
  }
}

struct Time {
  let hours: Double
  let minutes: Double
  let seconds: Double

  var totalDuration: Double

  init(hours: Double, minutes: Double, seconds: Double) {
    self.hours = hours
    self.minutes = minutes
    self.seconds = seconds
    self.totalDuration = Double(hours * minutes * seconds)
  }
}

struct ContentView: View {
  @State private var remainingTime: Double = 5 * 60
  @State private var isTimerRunning = false

  // time
  let time = Time(hours: 1.5, minutes: 60, seconds: 60)
  let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    

  // buttons
  var buttonTime1: Double = 5
  let buttonTime2: Double = 10
  let buttonTime3: Double = 25

  func playSound() {
    guard let path = Bundle.main.path(forResource: "alarm", ofType: "mp3") else {
      return
    }
    let url = URL(fileURLWithPath: path)

    do {
      player = try AVAudioPlayer(contentsOf: url)
      player?.play()

    } catch let error {
      print(error.localizedDescription)
    }
  }

  var body: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        Text(formatTime(remainingTime: remainingTime))
          .font(.largeTitle)
          .fontWeight(.regular)
          .padding()
      }
      SliderView(
        sliderColor: isTimerRunning ? Color.red : Color.white,
        totalDuration: time.totalDuration,
        remainingTime: $remainingTime
      )
      HStack {
        Button(action: {
          if isTimerRunning {
            stopTimer()
          } else {
            startTimer()
          }
        }) {
          Text(isTimerRunning ? "Stop" : "Start")
            .font(.title)
            .foregroundColor(isTimerRunning ? .red : .white)
            .animation(.easeInOut(duration: 0.2))
            .background(.clear)
            .cornerRadius(0)
        }
        .buttonStyle(PlainButtonStyle())
        Spacer()

        // time button 1
        Button(String(format: "%.0fm", buttonTime1)) {
          remainingTime = buttonTime1 * 60
        }
        .font(.title2)
        .foregroundColor(.white)
        .background(.clear)
        .opacity((remainingTime == (buttonTime1 * 60) && !(isTimerRunning)) ? 1 : 0.55)
        .buttonStyle(PlainButtonStyle())
        Spacer()

        // time button 2
        Button(String(format: "%.0fm", buttonTime2)) {
          remainingTime = buttonTime2 * 60
        }
        .font(.title2)
        .foregroundColor(.white)
        .background(.clear)
        .opacity((remainingTime == buttonTime2 * 60 && !(isTimerRunning)) ? 1 : 0.55)
        .buttonStyle(PlainButtonStyle())
        Spacer()

        // time button 3
        Button(String(format: "%.0fm", buttonTime3)) {
          remainingTime = buttonTime3 * 60
        }
        .font(.title2)
        .foregroundColor(.white)
        .background(.clear)
        .opacity((remainingTime == buttonTime3 * 60 && !(isTimerRunning)) ? 1 : 0.55)
        .buttonStyle(PlainButtonStyle())
        Spacer()
      }
    }
    .onReceive(timer) { _ in
      if isTimerRunning && remainingTime > 0 {
        remainingTime -= 1
        if remainingTime <= 0 {
          stopTimer()
          playSound()
        }
      }
    }
    .padding()
    .background(VisualEffectView())
  }

  private func startTimer() {
    isTimerRunning = true
  }

  private func stopTimer() {
    isTimerRunning = false
  }

  private func formatTime(remainingTime: Double) -> String {
    let hours = Int(remainingTime / 3600)
    let minutes = Int((remainingTime / 60).truncatingRemainder(dividingBy: 60))
    let seconds = Int(remainingTime.truncatingRemainder(dividingBy: 60))
    if remainingTime >= 3600 {
      return String(format: "%2d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }
}
