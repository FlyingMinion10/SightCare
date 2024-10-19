import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var mainTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var shortTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var mainTimerRunning = false
    @State private var shortTimerRunning = false
    @State private var showAlert = false
    @State private var alertSound: AVAudioPlayer?
    
    // Variables para el tiempo restante y ajustes de temporizadores
    @State private var mainTimeRemaining = 1200 // 20 minutos en segundos
    @State private var shortTimeRemaining = 20  // 20 segundos
    @State private var mainTimeSetting: Double = 20 // Ajuste inicial en minutos
    @State private var shortTimeSetting: Double = 20 // Ajuste inicial en segundos
    
    // Variable para cambiar a la vista de temporizador grande
    @State private var largeMode = true
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 20
    @State private var selectedShortMinutes: Int = 0
    @State private var selectedShortSeconds: Int = 20
    @State private var showMainTimePicker = false
    @State private var showShortTimePicker = false


    var body: some View {
        ZStack {
            VStack {
                // Ajuste del temporizador principal
                HStack(alignment: .center) {
                    Text("\nPomodoro Timer")
                        .font(.system(size: 40))
                    Text("\n🍅")
                        .font(.system(size: 40))
                }
                if !(mainTimerRunning || shortTimerRunning || largeMode) {
                    VStack(alignment: .leading) {
                        Text("Main Timer (minutes): \(Int(mainTimeSetting))")
                        Slider(value: $mainTimeSetting, in: 1...60, step: 1)
                            .padding(.horizontal)
                    }
                    .padding()
                    
                    // Ajuste del temporizador corto
                    VStack(alignment: .leading) {
                        Text("Short Timer (seconds): \(Int(shortTimeSetting))")
                        Slider(value: $shortTimeSetting, in: 10...60, step: 1)
                            .padding(.horizontal)
                    }
                    .padding()
                    
                    // MARK: - Large Mode Clock
                } else if !(mainTimerRunning || shortTimerRunning) {
                    // Mostrar tiempo preseleccionado para el temporizador principal
                    Button(action: { showMainTimePicker.toggle() }) {
                        HStack {
                            Text("Main Timer:")
                                .font(.title2)
                            Text("\(selectedHours) h \(selectedMinutes) m")
                                .font(.title2)
                                .foregroundStyle(Color.orange)
                        }
                        .padding()
                    }
                    
                    // Mostrar tiempo preseleccionado para el temporizador corto
                    Button(action: { showShortTimePicker.toggle() }) {
                        HStack {
                            Text("Short Timer:")
                                .font(.title2)
                            Text("\(selectedShortMinutes) m \(selectedShortSeconds) s")
                                .font(.title2)
                                .foregroundStyle(Color.orange)
                        }
                        .padding()
                    }
                }
                
                // Mostrar tiempo restante
                if !(mainTimerRunning || shortTimerRunning || largeMode) {
                    Text(String(Int(mainTimeSetting)) + ":00")
                        .font(.largeTitle)
                        .padding()
                    Text("00:" + String(Int(shortTimeSetting)))
                        .font(.title2)
                        .padding(1)
                } else if (largeMode && !mainTimerRunning) {
                    Spacer()
                    Circle()
                        .stroke(Color.orange, lineWidth: 10)
                        .frame(width: 200, height: 200)
                } else {
                    // Rueda de progreso con tiempo restante
                    Spacer()
                    ZStack {
                        // Círculo completo gris de fondo
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                            .frame(width: 200, height: 200)
                        
                        // Círculo de progreso que se va "consumiendo" de naranja a gris
                        Circle()
                            .trim(from: 0.0, to: mainTimerRunning ? CGFloat(mainTimeProgress()) : CGFloat(shortTimeProgress()))
                            .stroke(Color.orange, lineWidth: 10)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 200, height: 200)
                            .animation(.linear, value: mainTimerRunning ? CGFloat(mainTimeProgress()) : CGFloat(shortTimeProgress()))
                        
                        // Mostrar tiempo restante en el centro
                        Text(mainTimerRunning ? formatTime(seconds: mainTimeRemaining) : formatTime(seconds: shortTimeRemaining))
                            .font(.largeTitle)
                            .padding()
                    }
                    .padding()
                }
                
                // Botón de detener
                Spacer()
                if mainTimerRunning || shortTimerRunning {
                    HStack {
                        Spacer()
                        Button(action: stopTimers) {
                            Image(systemName: "stop.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                        }
                        .background(Color.red)
                        .clipShape(Circle())
                        .padding(.trailing, 30)
                    }
                } else {
                    ZStack {
                        HStack {
                            Button(action: { largeMode.toggle(); updateMainTimeSetting() }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                    .padding()
                            }
                            .padding(.leading, 30)
                            Spacer()
                        }
                        Button(action: startMainTimer) {
                            Text("Start")
                                .font(.largeTitle)
                                .padding()
                        }
                    }
                }
            }
//            .background(.black.opacity(0.9))
            .foregroundStyle(Color.white)
            .onReceive(mainTimer) { _ in
                if mainTimerRunning {
                    if mainTimeRemaining > 0 {
                        mainTimeRemaining -= 1
                    } else {
                        playAlertSound()
                        mainTimerRunning = false
                        shortTimerRunning = true
                        shortTimeRemaining = Int(shortTimeSetting) // Reiniciar el temporizador corto
                    }
                }
            }
            .onReceive(shortTimer) { _ in
                if shortTimerRunning {
                    if shortTimeRemaining > 0 {
                        shortTimeRemaining -= 1
                    } else {
                        shortTimerRunning = false
                        mainTimerRunning = true
                        mainTimeRemaining = Int(mainTimeSetting) * 60 // Reiniciar el temporizador principal
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Alarma"), message: Text("Toque la pantalla"), dismissButton: .default(Text("OK"), action: startShortTimer))
            }
            .blur(radius: (showShortTimePicker || showMainTimePicker) ? 10 : 0)
            
            if showMainTimePicker {
                VStack {
                    Text("Select Main Timer")
                        .font(.headline)
                        .padding()
                        .foregroundStyle(Color.white)
                    HStack {
                        Picker("Hours", selection: $selectedHours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour) h")
                                    .foregroundStyle(Color.gray)
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        .clipped()
                        
                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach(1..<60) { minute in
                                Text("\(minute) m")
                                    .foregroundStyle(Color.gray)
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        .clipped()
                    }
                    .padding()
                    
                    Button("Done") {
                        updateMainTimeSetting()
                        showMainTimePicker = false
                    }
                    .padding()
                    .foregroundStyle(Color.orange)
                }
                .background(.black.opacity(0.8))
                .background(.white)
                .cornerRadius(20)
            }
            
            if showShortTimePicker {
                VStack {
                    Text("Select Short Timer")
                        .font(.headline)
                        .padding()
                        .foregroundStyle(Color.white)
                    HStack {
                        Picker("Minutes", selection: $selectedShortMinutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute) m")
                                    .foregroundStyle(Color.gray)
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        .clipped()
                        
                        Picker("Seconds", selection: $selectedShortSeconds) {
                            ForEach(1..<60) { second in
                                Text("\(second) s")
                                    .foregroundStyle(Color.gray)
                                    .tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        .clipped()
                    }
                    .padding()
                    
                    Button("Done") {
                        updateShortTimeSetting()
                        showShortTimePicker = false
                    }
                    .padding()
                    .foregroundStyle(Color.orange)
                }
                .background(.black.opacity(0.8))
                .background(.white)
                .cornerRadius(20)
            }
        }
        .background(.black.opacity(0.9))
    }
    
    private func updateMainTimeSetting() {
        mainTimeSetting = Double((selectedHours * 60) + selectedMinutes)
    }
    
    private func updateShortTimeSetting() {
        shortTimeSetting = Double((selectedShortMinutes * 60) + selectedShortSeconds)
    }
    
    func startMainTimer() {
        mainTimerRunning = true
        mainTimeRemaining = Int(mainTimeSetting) * 60 // Ajustar el temporizador principal según la configuración del usuario
    }
    
    func startShortTimer() {
        shortTimerRunning = true
        shortTimeRemaining = Int(shortTimeSetting) // Ajustar el temporizador corto según la configuración del usuario
    }
    
    func stopTimers() {
        mainTimerRunning = false
        shortTimerRunning = false
    }
    
    func playAlertSound() {
        guard let url = Bundle.main.url(forResource: "alarma", withExtension: "mp3") else { return }
        do {
            alertSound = try AVAudioPlayer(contentsOf: url)
            alertSound?.play()
        } catch {
            print("Error al reproducir el sonido de la alarma")
        }
        showAlert = true
    }
    
    func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Funciones para calcular el progreso del tiempo restante
    func mainTimeProgress() -> Double {
        return Double(mainTimeRemaining) / Double(Int(mainTimeSetting) * 60)
    }

    func shortTimeProgress() -> Double {
        return Double(shortTimeRemaining) / Double(Int(shortTimeSetting))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
