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
	case `default`
}

struct DynamicSearchView: View {
	@Binding var text: String
	@FocusState var titleInputIsFocused: Bool
	@FocusState var titleInputTextFieldIsFocused: Bool
	@State var isShowSuggestions: Bool = false
	@State var selectedIndex: Int = -1
	var suggestionDidSelect: ((Int) -> Void)?
	var categoryDidSelect: ((Int) -> Void)?
	var didSave: (() -> Void)?
	
	@State private var filteredSuggestions: [Suggestion] = []
	@State private var filteredCategories: [Category] = []
	
	var originalSuggestion: [Suggestion] = []
	var originalCategories: [Category]
	@State var suggestionType: SuggestionType = .default
	var suggestions: [Suggestion] {
		if text.isEmpty {
			return originalSuggestion
		} else {
			return filteredSuggestions
		}
	}
	
	init(text: Binding<String>, suggestions: [Suggestion], categories: [Category], suggestionDidSelect: ((Int) -> Void)? = nil, categoryDidSelect: ((Int) -> Void)? = nil, didSave: (() -> Void)? = nil) {
		self._text = text
		self.originalSuggestion = suggestions
		self.originalCategories = categories
		self.suggestionDidSelect = suggestionDidSelect
		self.categoryDidSelect = categoryDidSelect
		self.didSave = didSave
	}
	
	var body: some View {
		ZStack {
			VStack {
				HStack {
					VStack {
						TextField("What’s your focus?...", text: $text)
							.textFieldStyle(.plain)
							.focusable()
							.focused($titleInputTextFieldIsFocused)
							.onChange(of: titleInputIsFocused) { _, _ in
								isShowSuggestions = true
							}
							.onChange(of: titleInputTextFieldIsFocused) { oldValue, newValue in
								isShowSuggestions = true
							}
					}
					
					if !text.isEmpty {
						Image(systemName: "xmark.circle.fill")
							.foregroundColor(.gray)
							.onTapGesture {
								text = ""
								titleInputTextFieldIsFocused = true
							}
					}
				}
				.padding(.vertical, 8)
				.padding(.horizontal, 12)
				.background(.white)
				.clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
					.onChange(of: text, { oldValue, newValue in
						textFieldOnChanged(text: newValue)
						selectedIndex = -1
					})
					.overlay(alignment: .top) {
						if !suggestions.isEmpty, titleInputTextFieldIsFocused, isShowSuggestions {
							VStack(spacing: 0) { // add shadow?
								
								ForEach(Array(zip(suggestions.indices, suggestions)), id: \.0) { (index, item) in
									let isSelected = index == selectedIndex
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
										selectedIndex = index
										itemDidSelect()
									}
									.background( isSelected ? .blue : .white)
									
									if index != suggestions.count - 1 {
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
			.onKeyPress(.downArrow) {
				if selectedIndex < suggestions.count - 1 {
					selectedIndex += 1
				}
				return .handled
			}
			.onKeyPress(.upArrow) {
				if selectedIndex > 0 {
					selectedIndex -= 1
				}
				return .handled
			}
			.onKeyPress(.return) {
				itemDidSelect()
				return .handled
			}
			.onKeyPress(.escape) {
				isShowSuggestions = false
				return .handled
			}
		}
		.zIndex(99)
	}

	func itemDidSelect() {
		if suggestionType == .category {
			categoryDidSelect?(suggestions[selectedIndex].id)
			if let title = text.components(separatedBy: "@").first {
				text = title
			}
		}
		
		if suggestionType == .default {
			if text.isEmpty, selectedIndex >= 0, selectedIndex < originalSuggestion.count {
				suggestionDidSelect?(originalSuggestion[selectedIndex].id)
				text = originalSuggestion[selectedIndex].title
			}
			
			isShowSuggestions.toggle()
			didSave?()
			text = ""
		}
	}
	
	func textFieldOnChanged(text: String) {
		suggestionType = text.contains("@") ? .category : .default
		if suggestionType == .category {
			if text.count == 1 {
				filteredSuggestions = originalCategories.map { Suggestion(id: $0.id, title: $0.title, color: $0.color) }
			} else {
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
		
		if suggestionType == .default {
			guard !text.isEmpty else {
				filteredSuggestions = originalSuggestion.map {
					Suggestion(id: $0.id, title: $0.title, color: $0.color)
				}
				return
			}
			
			filteredSuggestions = originalSuggestion.filter { $0.title.lowercased().contains(text.lowercased()) }.map { Suggestion(id: $0.id, title: $0.title, color: $0.color )}
		}
		selectedIndex = 0
	}
}

#Preview {
	DynamicSearchView(text: .constant(""), suggestions: [], categories: [])
}
