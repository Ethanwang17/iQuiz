//
//  ContentView.swift
//  iQuiz
//
//  Created by Ethan Wang on 5/1/24.
//

import SwiftUI

struct QuizTopic: Identifiable {
    var id = UUID()
    var icon: String
    var title: String
    var description: String
}

struct ContentView: View {
    @State private var showingAlert = false
    let quizTopics = [
        QuizTopic(icon: "🔢", title: "Mathematics", description: "Math questions and equations"),
        QuizTopic(icon: "🦸", title: "Marvel Super Heroes", description: "Marvel super hero trivia"),
        QuizTopic(icon: "🔬", title: "Science", description: "Science facts and knowledge")
    ]
    
    var body: some View {
        NavigationView {
            List(quizTopics) { topic in
                NavigationLink(destination: QuizDetailView(topic: topic)) {
                    HStack {
                        Text(topic.icon)
                            .font(.title)
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
                        showingAlert = true
                    }
                    .alert("Settings Go Here", isPresented: $showingAlert) {
                        Button("OK", role: .cancel) {}
                    }
                }
            }
        }
    }
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
