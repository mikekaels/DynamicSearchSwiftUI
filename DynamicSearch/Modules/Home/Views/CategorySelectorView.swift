//
//  SessionSearchTextField.swift
//  DynamicSearch
//
//  Created by Santo Michael on 27/04/24.
//

import SwiftUI

struct Category: Identifiable {
	let id: Int
	let title: String
	let color: Color
}

struct CategoryView: View {
	var title: String
	var color: Color
	var isSelected: Bool = false
	var body: some View {
		HStack(spacing: 5) {
			Image(systemName: "circle.fill")
				.resizable()
				.frame(width: 6, height: 6)
				.foregroundColor(color)
			Text(title)
				.foregroundColor(isSelected ? .white : .black)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

struct CategorySelectorView: View {
	var categories: [Category] = []
	var selectedCategory: Category
	var itemDidSelect: ((Int) -> Void)? = nil
	@State var selectedIndex: Int = -1
	@State var isShowCategories: Bool = false
	@FocusState var categoryIsFocused: Bool
	
	
	var body: some View {
		ZStack {
			VStack {
				HStack {
					HStack(spacing: 4) {
						CategoryView(title: selectedCategory.title, color: selectedCategory.color)
					}
					Spacer()
					Image(systemName: isShowCategories ? "chevron.up" : "chevron.down")
						.foregroundColor(.gray)
				}
				.padding(.vertical, 8)
				.padding(.horizontal, 12)
				.background(.white)
				.clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
					.onTapGesture {
						isShowCategories.toggle()
						categoryIsFocused.toggle()
					}
					.overlay(alignment: .top) {
						if isShowCategories {
							VStack(spacing: 0) {
								ForEach(Array(categories.enumerated()), id: \.offset) { (index, item) in
									let isSelected = index == selectedIndex && categoryIsFocused
									CategoryView(title: item.title, color: item.color, isSelected: isSelected)
										.padding(.vertical, 10.5)
										.padding(.horizontal, 12)
										.contentShape(Rectangle())
										.onTapGesture {
											itemDidSelect(index: index)
										}
									.background(isSelected ? .blue : .white)
									
									if index != categories.count - 1 {
										Divider()
									}
								}
							}
							.focusable()
							.focused($categoryIsFocused)
							.focusEffectDisabled()
							.onKeyPress(.downArrow) {
								if selectedIndex < categories.count - 1 {
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
								isShowCategories = false
								return .handled
							}
							.background(.white)
							.cornerRadius(4)
							.offset(y: 40)
							.shadow(color: .gray, radius: 5, x: 0, y: 2)
						}
					}
					
			}
		}
		.zIndex(100)
	}
	
	func itemDidSelect(index: Int? = nil) {
		if let index = index {
			selectedIndex = index
			itemDidSelect?(categories[index].id)
			isShowCategories.toggle()
		} else {
			itemDidSelect?(categories[selectedIndex].id)
			isShowCategories.toggle()
		}
	}
}

#Preview {
	CategorySelectorView(selectedCategory: .init(id: 0, title: "Category", color: .green))
}
