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
					textOnChange(newValue)
				})
				.onKeyPress(.downArrow) {
					onKeyPressDown()
					return .handled
				}
				.onKeyPress(.upArrow) {
					onKeyPressUp()
					return .handled
				}
				.onKeyPress(.return) {
					onKeyPressReturn()
					return .handled
				}
				.onKeyPress(.escape) {
					showDropDown = false
					return .handled
				}
				.onKeyPress(characters: .letters, action: { keyPress in
					isKeyboardTypes = true
					return .ignored
				})
				.onKeyPress { keyPress in
					if keyPress.key == "\u{7f}" || keyPress.key == "@" {
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
}

extension DynamicSearchView {
	func categoryDidChange(_ text: String) {
		if isKeyboardTypes {
			filterCategory(text: text)
		}
		
		if dropDownIndex != -1, categoryUserInput.isEmpty {
			filterCategory(text: text)
		}
		
		if dropDownIndex == -1 {
			filterCategory(text: text)
		}
	}
	
	func userInputDidChange(_ text: String) {
		if dropDownIndex != -1, filteredSuggestions.count != 0, text != filteredSuggestions[dropDownIndex].title {
			filterRecentInput(text: text)
		}
		
		if dropDownIndex == -1 {
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
			if filteredCategory.isEmpty {
				suggestionType = .recentInput
			}
			filteredSuggestions = filteredCategory.map { Suggestion(id: $0.id, title: $0.title, color: $0.color) }
		}
	}
	
	func filterRecentInput(text: String) {
		if suggestionType == .recentInput {
			if text.isEmpty {
				filteredSuggestions = originalSuggestion.map { Suggestion(id: $0.id, title: $0.title, color: $0.color) }
			} else {
				filteredSuggestions = originalSuggestion.filter { $0.title.lowercased().contains(text.lowercased()) }
					.map { Suggestion(id: $0.id, title: $0.title, color: $0.color )}
			}
		}
	}
	
	func textOnChange(_ text: String) {
		suggestionType = text.contains("@") ? (text.first == "@" ? .category : .categoryOnRecentInput) : .recentInput
		
		if let first = text.components(separatedBy: "@").first,
		   let last = text.components(separatedBy: "@").last {
			if isKeyboardTypes {
				if suggestionType == .recentInput {
					dropDownIndex = -1
					titleUserInput = first
				} else if suggestionType == .category {
					dropDownIndex = -1
					categoryUserInput = last
				} else if suggestionType == .categoryOnRecentInput {
					dropDownIndex = -1
					titleUserInput = first
					categoryUserInput = last
				}
			} else if !first.isEmpty {
				titleUserInput = first
			}
		}
		
		if text.isEmpty {
			isKeyboardTypes = false
			filteredSuggestions = originalSuggestion
		} else if text.isEmpty, suggestionType == .category {
			filterCategory(text: categoryUserInput)
		}
		
		if suggestionType == .category || suggestionType == .categoryOnRecentInput {
			categoryDidChange(categoryUserInput)
		} else if suggestionType == .recentInput {
			userInputDidChange(titleUserInput)
		}
	}
	
	func onKeyPressDown() {
		isKeyboardTypes = false
		
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
	}
	
	func onKeyPressUp() {
		isKeyboardTypes = false
		
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
	}
	
	func onKeyPressReturn() {
		if suggestionType == .categoryOnRecentInput {
			categoryDidSelect?(filteredSuggestions[dropDownIndex].id)
			text = titleUserInput
			suggestionType = .recentInput
		} else if suggestionType == .category, dropDownIndex != -1, dropDownIndex < filteredSuggestions.count {
			categoryDidSelect?(filteredSuggestions[dropDownIndex].id)
			text = ""
			titleUserInput = ""
		} else {
			titleDidSave?(text)
			text = ""
			titleUserInput = ""
		}
		
		dropDownIndex = -1
		categoryUserInput = ""
	}
}

extension DynamicSearchView {
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
}

#Preview {
	DynamicSearchView(text: .constant(""), suggestions: [], categories: [])
}
