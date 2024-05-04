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
	case categoryOnRecentInput
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
	@FocusState private var sugestionFocused: Bool
	@State private var isKeyboardTypes: Bool = false
	@State var titleUserInput: String = ""
	@State var categoryUserInput: String = ""
	
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
					showDropDown = newValue == .inputTitle
				}
				.onChange(of: text, { oldValue, newValue in
					let isContainAt = text.contains("@")
					suggestionType = isContainAt ? (text.first == "@" ? .category : .categoryOnRecentInput) : .recentInput
					
					let input = newValue.filter { $0 != "@" }
					
					if isKeyboardTypes, suggestionType == .recentInput {
						dropDownIndex = -1
						titleUserInput = input
					}
					
					if isKeyboardTypes, suggestionType == .category {
						dropDownIndex = -1
						categoryUserInput = input
					}
					
					if isKeyboardTypes, suggestionType == .categoryOnRecentInput {
						if let title = newValue.components(separatedBy: "@").first {
							titleUserInput = title
						}
						
						if let category = newValue.components(separatedBy: "@").last {
							categoryUserInput = category
						}
					}
					
					if newValue.isEmpty {
						isKeyboardTypes = false
						filteredSuggestions = originalSuggestion
					} else if newValue.isEmpty, suggestionType == .category {
						filterCategory(text: categoryUserInput)
					}
					
					if suggestionType == .category || suggestionType == .categoryOnRecentInput {
						categoryDidChange(categoryUserInput)
					} else if suggestionType == .recentInput {
						userInputDidChange(titleUserInput)
					}
				})
				.onKeyPress(characters: .letters, action: { keyPress in
					isKeyboardTypes = true
					return .ignored
				})
				.onKeyPress(.downArrow) {
					if suggestionType == .category || suggestionType == .recentInput {
						isKeyboardTypes = false
					}
					
					if dropDownIndex < filteredSuggestions.count - 1 {
						dropDownIndex += 1
					} else {
						dropDownIndex = -1
					}
					
					
					
					if dropDownIndex == -1 {
						if suggestionType == .categoryOnRecentInput {
							text = titleUserInput + "@" + categoryUserInput
						} else if suggestionType == .category {
							text = "@" + categoryUserInput
						} else {
							text = titleUserInput
						}
					} else {
						let suggestion = filteredSuggestions[dropDownIndex].title
						if suggestionType == .categoryOnRecentInput {
							text = titleUserInput + "@" + suggestion
						} else if suggestionType == .category {
							text = "@" + suggestion
						} else {
							text = suggestion
						}
					}
					
					return .handled
				}
				.onKeyPress(.upArrow) {
					if suggestionType == .category || suggestionType == .recentInput {
						isKeyboardTypes = false
					}
					
					if dropDownIndex > -1 {
						dropDownIndex -= 1
					}
					else {
						dropDownIndex = filteredSuggestions.count - 1
					}
					
					if dropDownIndex == -1 {
						if suggestionType == .categoryOnRecentInput {
							text = titleUserInput + "@" + categoryUserInput
						} else if suggestionType == .category {
							text = "@" + categoryUserInput
						} else {
							text = titleUserInput
						}
					} else {
						let suggestion = filteredSuggestions[dropDownIndex].title
						if suggestionType == .categoryOnRecentInput {
							text = titleUserInput + "@" + suggestion
						} else if suggestionType == .category {
							text = "@" + suggestion
						} else {
							text = suggestion
						}
					}
					return .handled
				}
				.onKeyPress(.upArrow) {
					return .ignored
				}
				.onKeyPress(.return) {
					if suggestionType == .categoryOnRecentInput {
						let selectedCategory = filteredSuggestions[dropDownIndex]
						categoryDidSelect?(selectedCategory.id)
						text = titleUserInput
						categoryUserInput = ""
						dropDownIndex = -1
						suggestionType = .recentInput
					}
						
					else if suggestionType == .category {
						let selectedCategory = filteredSuggestions[dropDownIndex]
						categoryDidSelect?(selectedCategory.id)
						text = ""
						titleUserInput = ""
						categoryUserInput = ""
						dropDownIndex = -1
					}
					
					else {
						titleDidSave?(text)
						text = ""
						titleUserInput = ""
						categoryUserInput = ""
						dropDownIndex = -1
					}
					
					return .handled
				}
				.onKeyPress(.escape) {
					showDropDown = false
					return .handled
				}
				.onKeyPress { keyPress in
					if keyPress.key == "\u{7f}" {
						isKeyboardTypes = true
					}
					return .ignored
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
			VStack(spacing: 0) {
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
			.background(.white)
			.cornerRadius(4)
			.offset(y: 40)
			.shadow(color: .gray, radius: 5, x: 0, y: 2)
		}
	}
	
	func categoryDidChange(_ text: String) {
		if dropDownIndex != -1, categoryUserInput.isEmpty {
			filterCategory(text: categoryUserInput)
		}
		
		if dropDownIndex == -1 {
			filterCategory(text: categoryUserInput)
		}
	}
	
	func userInputDidChange(_ text: String) {
		if dropDownIndex != -1,
		   filteredSuggestions.count != 0,
		   text != filteredSuggestions[dropDownIndex].title {
			filterRecentInput(text: text)
		}
		
		if dropDownIndex == -1, isKeyboardTypes {
			filterRecentInput(text: text)
		}
	}

	func itemDidSelect() {
		if suggestionType == .recentInput {
			if dropDownIndex >= -1 {
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
		if text.isEmpty {
			filteredSuggestions = originalCategories.map { Suggestion(id: $0.id, title: $0.title, color: $0.color) }
		} else {
			let filteredCategory = originalCategories.filter { $0.title.lowercased().contains(text.lowercased())}
			filteredSuggestions = filteredCategory.map { Suggestion(id: $0.id, title: $0.title, color: $0.color) }
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
