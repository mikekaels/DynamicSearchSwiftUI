//
//  DynamicSearchView.swift
//  DynamicSearch
//
//  Created by Santo Michael on 28/04/24.
//

import SwiftUI

struct Suggestion: Identifiable {
	let id: Int
	let title: String
	var color: Color? = nil
}

enum SuggestionType {
	case category
	case recentInput
}

struct DynamicSearchView: View {
	@Binding var text: String
	@FocusState var focusState: FocusType?
	var titleDidSave: ((_ title: String) -> Void)?
	var categoryDidSelect: ((Int) -> Void)?
	
	@State var showDropDown: Bool = false
	@State var dropDownIndex: Int = -1
	@State var suggestionType: SuggestionType = .recentInput
	@State private var filteredSuggestions: [Suggestion] = []
	@State private var filteredCategories: [Category] = []
	
	var originalSuggestion: [Suggestion] = []
	var originalCategories: [Category]
	
	init(text: Binding<String>, suggestions: [Suggestion], categories: [Category], titleDidSave: ((_ title: String) -> Void)? = nil, categoryDidSelect: ((Int) -> Void)? = nil) {
		self._text = text
		self.originalSuggestion = suggestions
		self.originalCategories = categories
		self.titleDidSave = titleDidSave
		self.categoryDidSelect = categoryDidSelect
	}
	
	var body: some View {
		ZStack {
			VStack {
				textFieldView
					.padding(.vertical, 8)
					.padding(.horizontal, 12)
					.background(.white)
					.clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
					.overlay(alignment: .top) {
						dropDownView
					}
					.onAppear {
						filteredSuggestions = originalSuggestion
					}
			}
		}
		.zIndex(99)
	}
	
	var textFieldView: some View {
		HStack {
			VStack {
				TextField("What’s your focus?...", text: $text)
				.textFieldStyle(.plain)
				.focusable()
				.focused($focusState, equals: .inputTitle)
				.onChange(of: focusState) { _, newValue in
					showDropDown = (newValue == .inputTitle || newValue == .suggestion)
				}
				.onChange(of: text, { oldValue, newValue in
					print(text)
					dropDownIndex = -1
					guard !text.isEmpty else {
						filteredSuggestions = originalSuggestion
						return
					}
					suggestionType = text.contains("@") ? .category : .recentInput
					if suggestionType == .category {
						filterCategory(text: text)
					} else {
						filterRecentInput(text: text)
					}
				})
				.onKeyPress(.downArrow) {
					dropDownIndex += 1
					focusState = dropDownIndex >= 0 ? .suggestion : .inputTitle
					return .handled
				}
				.onKeyPress(.return) {
					titleDidSave?(text)
					text = ""
					showDropDown = false
					
					return .handled
				}
				
			}
			
			if !text.isEmpty {
				Image(systemName: "xmark.circle.fill")
					.foregroundColor(.gray)
					.onTapGesture {
						text = ""
					}
			}
		}
	}
	
	@ViewBuilder
	var dropDownView: some View {
		if showDropDown {
			VStack(spacing: 0) { // add shadow?
				ForEach(Array(zip(filteredSuggestions.indices, filteredSuggestions)), id: \.0) { (index, item) in
					let isSelected = index == dropDownIndex
					HStack(spacing: 5) {
						if let color = item.color {
							Image(systemName: "circle.fill")
								.resizable()
								.frame(width: 6, height: 6)
								.foregroundColor(color)
						}
						Text(item.title)
							.frame(maxWidth: .infinity, alignment: .leading)
							.foregroundColor(isSelected ? .white : .black)
					}
					.contentShape(Rectangle())
					.padding(.all, 8)
					.onTapGesture {
						dropDownIndex = index
						itemDidSelect()
					}
					.background( isSelected ? .blue : .white)
					
					if index != filteredSuggestions.count - 1 {
						Divider()
					}
				}
			}
			.focusable()
			.focused($focusState, equals: .suggestion)
			.focusEffectDisabled()
			.onKeyPress(.downArrow) {
				if dropDownIndex < filteredSuggestions.count - 1 {
					dropDownIndex += 1
				}
				return .handled
			}
			.onKeyPress(.upArrow) {
				if dropDownIndex > -1 {
					dropDownIndex -= 1
				}
				focusState = dropDownIndex >= 0 ? .suggestion : .inputTitle
				return .handled
			}
			.onKeyPress(.return) {
				itemDidSelect()
				return .handled
			}
			.onKeyPress(.escape) {
				showDropDown = false
				return .handled
			}
			.background(.white)
			.cornerRadius(4)
			.offset(y: 40)
			.shadow(color: .gray, radius: 5, x: 0, y: 2)
		}
	}
	

	func itemDidSelect() {
		if suggestionType == .recentInput {
			print("~ INDEX: ",dropDownIndex)
			if dropDownIndex >= 0 {
				titleDidSave?(filteredSuggestions[dropDownIndex].title)
			}
			text = ""
			showDropDown = false
			focusState = .session
			dropDownIndex = -1
		}
		
		if suggestionType == .category {
			categoryDidSelect?(filteredSuggestions[dropDownIndex].id)
			if let title = text.components(separatedBy: "@").first, title.count > 0 {
				text = title.last != " " ? title + " " : title
			} else {
				text = ""
			}
			suggestionType = .recentInput
			focusState = .inputTitle
			dropDownIndex = -1
		}
	}
	
	func filterCategory(text: String) {
		if text.count == 1 {
			filteredSuggestions = originalCategories.map { Suggestion(id: $0.id, title: $0.title, color: $0.color) }
		} 
		
		else if text.first == "@", let text = text.split(separator: "@").first {
			let filteredCategory = originalCategories.filter { $0.title.lowercased().contains(text.lowercased())}
			filteredSuggestions = filteredCategory.map { Suggestion(id: $0.id, title: $0.title, color: $0.color) }
		}
		
		else {
			if let text = text.split(separator: "@").dropFirst().first {
				let filteredCategory = originalCategories.filter { $0.title.lowercased().contains(text.lowercased())}
				filteredSuggestions = filteredCategory.map { Suggestion(id: $0.id, title: $0.title, color: $0.color) }
			} else if let text = text.split(separator: "@").dropFirst().first, !text.isEmpty  {
				let filteredCategory = originalCategories.filter { $0.title.lowercased().contains(text.lowercased())}
				filteredSuggestions = filteredCategory.map { Suggestion(id: $0.id, title: $0.title, color: $0.color) }
			} else {
				filteredSuggestions = originalCategories.map { Suggestion(id: $0.id, title: $0.title, color: $0.color) }
			}
		}
	}
	
	func filterRecentInput(text: String) {
		if suggestionType == .recentInput {
			guard !text.isEmpty else {
				filteredSuggestions = originalSuggestion.map {
					Suggestion(id: $0.id, title: $0.title, color: $0.color)
				}
				return
			}
			
			filteredSuggestions = originalSuggestion.filter { $0.title.lowercased().contains(text.lowercased()) }.map { Suggestion(id: $0.id, title: $0.title, color: $0.color )}
		}
	}
}

#Preview {
	DynamicSearchView(text: .constant(""), suggestions: [], categories: [])
}
