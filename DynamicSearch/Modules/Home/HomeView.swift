//
//  HomeView.swift
//  DynamicSearch
//
//  Created by Santo Michael on 27/04/24.
//

import SwiftUI

struct Session: Identifiable {
	let id: Int
	let title: String
	let categoryId: Int
	var isDone: Bool
}

struct HomeView: View {
	var categories: [Category] = [
		.init(id: 1, title: "Work", color: .red),
		.init(id: 2, title: "Wok", color: .gray),
		.init(id: 3, title: "Sleep", color: .black),
		.init(id: 4, title: "Games", color: .blue),
		.init(id: 5, title: "Music", color: .green),
		.init(id: 6, title: "Hobby", color: .yellow),
	]
	
	var suggestions: [Suggestion] = [
		.init(id: 1, title: "Slicing UI"),
		.init(id: 2, title: "Meeting with PM"),
		.init(id: 3, title: "API Integration"),
		.init(id: 4, title: "Meeting with Backend"),
		.init(id: 5, title: "Drawing"),
	]
	
	@State var sessions: [Session] = [
		.init(id: 1, title: "Slicing UI", categoryId: 1, isDone: true),
		.init(id: 2, title: "Meeting with PM", categoryId: 1, isDone: true),
		.init(id: 3, title: "API Integration", categoryId: 1, isDone: false),
		.init(id: 4, title: "Meeting with Backend", categoryId: 1, isDone: false),
		.init(id: 5, title: "Drawing", categoryId: 6, isDone: false),
	]
	
	@FocusState var sessionIsFocused: Bool
	@State var searchText: String = ""
	@State var titleText: String = ""
	@State var selectedSession: Int = -1
	@State var selectedCategory: Category = .init(id: -1, title: "Category", color: .green)
	
	var body: some View {
		VStack {
			CategorySelectorView(categories: categories, selectedCategory: selectedCategory) { id in
				sessionIsFocused = true
				categoryDidSelect(id)
			}
			
			DynamicSearchView(text: $titleText, suggestions: suggestions, categories: categories) { id in
				sessionIsFocused = true
			} categoryDidSelect: { id in
				categoryDidSelect(id)
			} didSave: {
				saveSession()
			}
			
			sessionView
			
			Spacer()
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 20)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(hex: "#E6E6E6"))
	}
	
	func categoryDidSelect(_ id: Int) {
		if let category = categories.first(where: { $0.id == id }) {
			selectedCategory = category
			print(category)
		}
	}
	
	func saveSession() {
		guard selectedCategory.id != -1 else { return }
		let session = Session(id: Int.random(in: 10...100), title: titleText, categoryId: selectedCategory.id, isDone: false)
		sessions.insert(session, at: 0)
	}
}

extension HomeView {
	var sessionView: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 4) {
				ForEach(Array(sessions.enumerated()), id: \.offset) { (index, session) in
					let isSelected = selectedSession == index
					HStack(spacing: 10) {
						Image(systemName: session.isDone ? "checkmark.square" : "square")
							.renderingMode(.template)
							.foregroundColor(isSelected ? .white : .black)
							.onTapGesture {
								sessions[index].isDone.toggle()
							}
						VStack(alignment: .leading, spacing: 0) {
							Text(session.title)
								.foregroundColor(isSelected ? .white : .black)
							if let category = categories.first(where: { $0.id == session.categoryId }) {
								CategoryView(title: category.title, color: category.color, isSelected: isSelected)
							}
						}
					}
					.contentShape(Rectangle())
					.onTapGesture {
						selectedSession = index
					}
					.padding(.horizontal, 8)
					.padding(.vertical, 10.5)
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(isSelected ? .blue : .white)
					.clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
				}
			}
		}
		.onAppear {
			sessionIsFocused = true
		}
		.focusable()
		.focused($sessionIsFocused)
		.focusEffectDisabled()
		.onKeyPress(.downArrow) {
			if selectedSession < sessions.count - 1 {
				selectedSession += 1
			}
			return .handled
		}
		.onKeyPress(.upArrow) {
			if selectedSession > 0 {
				selectedSession -= 1
			}
			return .handled
		}
		.onKeyPress(.return) {
			sessions[selectedSession].isDone.toggle()
			return .handled
		}
	}
}

#Preview {
    HomeView()
}
