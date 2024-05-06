//
//  ContentView.swift
//  iQuiz
//
//  Created by Ethan Wang on 5/1/24.
//

import SwiftUI
import Network

struct QuizTopic: Identifiable {
    var id = UUID()
    var title: String
    var description: String
}

struct ContentView: View {
    @State private var showingAlert = false
    @State private var invalidURLAlert = false
    @State private var isNetworkConnected = false
    
    @State private var url = ""
    @State private var quizTopics = [QuizTopic]()
    
    var body: some View {
        NavigationView {
            List(quizTopics) { topic in
                NavigationLink(destination: QuizDetailView(topic: topic)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(topic.title)
                                .font(.headline)
                            Text(topic.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("IQuiz")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        url = ""
                        showingAlert.toggle()
                    }
                    .alert("Enter Valid URL", isPresented: $showingAlert) {
                        TextField("Enter URL Here", text: $url)
                        Button("Cancel", role: .cancel) { }
                        Button("Check Now"){
                            downloadQuizData(from: url)
                        }
                    }
                }
            }
            .alert("Invalid URL", isPresented: $invalidURLAlert) {
                Button("OK", role: .cancel) { }
            }
            .alert("No Network Detected", isPresented: $isNetworkConnected) {
                Button("OK", role: .cancel) { }
            }
        }
        .onAppear {
            checkNetworkStatus()
            loadURLFromSettings()
        }
    }
    
    func loadURLFromSettings() {
        if let savedURL = UserDefaults.standard.string(forKey: "quizDataURL") {
            url = savedURL
            downloadQuizData(from: url)
        } else {
            let defaultURL = "https://tednewardsandbox.site44.com/questions.json"
            url = defaultURL
            downloadQuizData(from: defaultURL)
        }
    }
    
    func downloadQuizData(from urlString: String) {
        print("Downloading data from URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        UserDefaults.standard.set(urlString, forKey: "quizDataURL")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let quizData = try decoder.decode([QuizData].self, from: data)
                    DispatchQueue.main.async {
                        self.quizTopics = quizData.map {
                            QuizTopic(title: $0.title, description: $0.desc)
                        }
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            } else {
                invalidURLAlert = true
                print("No data received: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
    
    func checkNetworkStatus() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)
        
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("We're connected!")
            } else {
                isNetworkConnected = true
                print("No connection.")
            }
        }
        
        monitor.start(queue: queue)
    }
}

struct QuizData: Codable {
    let title: String
    let desc: String
    let questions: [Question]
}

struct Question: Codable {
    let text: String
    let answer: String
    let answers: [String]
}

struct QuizDetailView: View {
    var topic: QuizTopic
    
    var body: some View {
        Text("Questions for \(topic.title)")
            .font(.system(size: 20))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("\(topic.title) Quiz")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
