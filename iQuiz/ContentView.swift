//
//  ContentView.swift
//  iQuiz
//
//  Created by Ethan Wang on 5/1/24.
//

import SwiftUI

struct QuizTopic: Identifiable, Codable {
    var id = UUID()
    let title: String
    let desc: String
    let questions: [Question]
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
                NavigationLink(destination: QuestionListView(customTopic: topic)) {
                    HStack {
                        Text("🎯") // Emoji in a separate line
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text(topic.title)
                                .font(.headline)
                            Text(topic.desc)
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
            if let quizData = loadQuizDataFromFile() {
                self.quizTopics = quizData.map {
                    QuizTopic(title: $0.title, desc: $0.desc, questions: $0.questions)
                }
            }
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
                    let quizData = try decoder.decode([QuizTopic].self, from: data)
                    DispatchQueue.main.async {
                        self.quizTopics = quizData
                        UserDefaults.standard.set(url.absoluteString, forKey: "quizDataURL")
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

    func saveQuizDataToFile(quizData: [QuizData]) {
        let jsonEncoder = JSONEncoder()
        if let jsonData = try? jsonEncoder.encode(quizData) {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent("quizData.json")
            try? jsonData.write(to: fileURL)
        }
    }

    func loadQuizDataFromFile() -> [QuizData]? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("quizData.json")
        if let jsonData = try? Data(contentsOf: fileURL) {
            let jsonDecoder = JSONDecoder()
            if let quizData = try? jsonDecoder.decode([QuizData].self, from: jsonData) {
                return quizData
            }
        }
        return nil
}

struct QuizData: Codable {
    let title: String
    let desc: String
    let questions: [Question]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Question: Codable {
    let text: String
    let answer: String
    let answers: [String]
}

struct QuestionListView: View {
    let customTopic: QuizTopic
    @State private var currentIndex = 0
    @State private var answers: [String?] = []
    @State private var isAnswerViewShown = false
    @State private var userScore = 0

    var totalQuestions: Int {
        customTopic.questions.count
    }

    var currentQuestion: Question {
        customTopic.questions[currentIndex]
    }

    var body: some View {
        VStack {
            switch (currentIndex < customTopic.questions.count, isAnswerViewShown) {
            case (true, true):
                AnswerView(customQuestion: currentQuestion, correctAnswer: currentQuestion.answers[Int(currentQuestion.answer)! - 1], userAnswer: answers[currentIndex], dismissAction: {
                    isAnswerViewShown = false
                    currentIndex += 1
                })
            case (true, false):
                QuestionView(customQuestion: currentQuestion, didSelectAnswerIndex: didSelectAnswerIndex)
            default:
                FinishedView(score: userScore, totalQuestions: totalQuestions)
            }
        }
    }

    func didSelectAnswerIndex(_ answerIndex: Int?) {
        guard let answerIndex = answerIndex else {
            return
        }
        let userAnswer = currentQuestion.answers[answerIndex]
        answers.append(userAnswer)
        if userAnswer == currentQuestion.answers[Int(currentQuestion.answer)! - 1] {
            userScore += 1
        }
        isAnswerViewShown = true
    }
}

struct AnswerView: View {
    let customQuestion: Question
    let correctAnswer: String
    let userAnswer: String?
    let dismissAction: () -> Void

    var isAnswerCorrect: Bool {
        userAnswer == correctAnswer
    }

    var body: some View {
        VStack {
            Text(customQuestion.text)
                .padding()
                .font(.title)
            Text("Correct Answer: \(correctAnswer)")
                .padding()
                .foregroundColor(isAnswerCorrect ? .green : .red)
                .font(.title)
            Text(isAnswerCorrect ? "+1" : " ")
                .foregroundColor(.green)
            Button("Next") {
                dismissAction()
            }
            .padding()
        }
    }
}

struct QuestionView: View {
    let customQuestion: Question
    let didSelectAnswerIndex: (Int?) -> Void
    @State private var selectedAnswerIndex: Int?

    var body: some View {
        VStack {
            Text(customQuestion.text)
                .font(.title)
                .padding()

            ForEach(customQuestion.answers.indices, id: \.self) { index in
                Button(action: {
                    selectedAnswerIndex = index
                }) {
                    HStack {
                        Text(selectedAnswerIndex == index ? "✓" : "")
                            .foregroundColor(selectedAnswerIndex == index ? .green : .clear)
                            .font(.title)
                        Text(customQuestion.answers[index])
                    }
                    .padding()
                }
            }

            Spacer()

            Button("Next") {
                didSelectAnswerIndex(selectedAnswerIndex)
                selectedAnswerIndex = nil
            }
            .padding()
        }
    }
}

struct FinishedView: View {
    let score: Int
    let totalQuestions: Int

    var scoreText: String {
        let percentage = Double(score) / Double(totalQuestions)
        switch percentage {
        case 1.0:
            return "You got all correct! Amazing!"
        case 0.9..<1.0:
            return "Almost there! Great job!"
        case 0.7..<0.9:
            return "Well done! Keep it up!"
        case 0.5..<0.7:
            return "Not bad! Practice makes perfect!"
        default:
            return "Keep practicing to improve!"
        }
    }


    var body: some View {
        VStack {
            Text(scoreText)
                .font(.title)
                .padding()
            Text("Your Score: \(score) of \(totalQuestions) correct")
                .font(.headline)
                .padding()
        }
    }
}
