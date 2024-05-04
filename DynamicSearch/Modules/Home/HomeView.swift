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

enum FocusType: Equatable {
	case category
	case inputTitle
//	case suggestion
	case session
}

struct HomeView: View {
	var categories: [Category] = [
		.init(id: 1, title: "Work", color: .red),
		.init(id: 2, title: "Freelance", color: .gray),
		.init(id: 3, title: "Sleep", color: .black),
		.init(id: 4, title: "Games", color: .blue),
		.init(id: 5, title: "Music", color: .green),
		.init(id: 6, title: "Hobby", color: .yellow),
		.init(id: 7, title: "School", color: .brown),
		.init(id: 8, title: "Others", color: .orange),
	]
	
	@State var suggestions: [Suggestion] = [
		.init(id: 1, title: "Slicing UI"),
		.init(id: 2, title: "Meeting with PM"),
		.init(id: 3, title: "API Integration"),
		.init(id: 4, title: "Meeting with Backend"),
		.init(id: 5, title: "Drawing"),
		.init(id: 6, title: "API Meeting"),
		.init(id: 7, title: "API meet"),
		.init(id: 8, title: "google meet"),
		.init(id: 9, title: "Design UI"),
		.init(id: 10, title: "Fixing UI"),
		.init(id: 11, title: "Integration meeting"),
	]
	
	@State var sessions: [Session] = [
		.init(id: 1, title: "Slicing UI", categoryId: 1, isDone: true),
		.init(id: 2, title: "Meeting with PM", categoryId: 1, isDone: true),
		.init(id: 3, title: "API Integration", categoryId: 1, isDone: false),
		.init(id: 4, title: "Meeting with Backend", categoryId: 1, isDone: false),
		.init(id: 5, title: "Drawing", categoryId: 6, isDone: false),
	]
	
	@FocusState var focusState: FocusType?
	@State var searchText: String = ""
	@State var titleText: String = ""
	@State var sessionIndex: Int = 0
	@State var selectedCategory: Category = .init(id: -1, title: "Category", color: .green)
	
	var body: some View {
		VStack {
			CategorySelectorView(focusState: _focusState, 
								 categories: categories,
								 selectedCategory: selectedCategory) { id in
				categoryDidSelect(id)
			}
			
			DynamicSearchView(text: $titleText, 
							  suggestions: suggestions,
							  categories: categories) { title in
				saveSession(title: title)
			} categoryDidSelect: { id in
				categoryDidSelect(id)
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
		}
	}
	
	func saveSession(title: String) {
		
		guard !title.isEmpty, selectedCategory.id != -1, title.first != "@" else {
			focusState = .session
			return
		}
		
		let session = Session(id: Int.random(in: 100...100000), title: title, categoryId: selectedCategory.id, isDone: false)
		sessions.insert(session, at: 0)
		sessionIndex = 0
		focusState = .session
		if let suggestionIndex = suggestions.firstIndex(where: { $0.title.lowercased().contains(title.lowercased()) }) {
			let suggestin = suggestions[suggestionIndex]
			suggestions.remove(at: suggestionIndex)
			suggestions.insert(suggestin, at: 0)
		} else {
			suggestions.insert(.init(id: Int.random(in: 100...100000), title: title), at: 0)
		}
	}
}

extension HomeView {
	var sessionView: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 4) {
				ForEach(Array(sessions.enumerated()), id: \.offset) { (index, session) in
					let isSelected = sessionIndex == index && focusState == .session
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
						sessionIndex = index
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
			focusState = .session
		}
		.focusable()
		.focused($focusState, equals: .session)
		.focusEffectDisabled()
		.onKeyPress(.downArrow) {
			if sessionIndex < sessions.count - 1 {
				sessionIndex += 1
			}
			return .handled
		}
		.onKeyPress(.upArrow) {
			if sessionIndex > 0 {
				sessionIndex -= 1
			}
			return .handled
		}
		.onKeyPress(.return) {
			sessions[sessionIndex].isDone.toggle()
			return .handled
		}
	}
}

#Preview {
    HomeView()
}
