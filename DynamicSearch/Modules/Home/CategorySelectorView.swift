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
	@FocusState var focusState: FocusType?
	var categories: [Category] = []
	var selectedCategory: Category
	var itemDidSelect: ((Int) -> Void)?
	@State var selectedIndex: Int = 0
	@State var showDropDown: Bool = false
	
	var body: some View {
		ZStack {
			VStack {
				HStack {
					HStack(spacing: 4) {
						CategoryView(title: selectedCategory.title, color: selectedCategory.color)
					}
					Spacer()
					Image(systemName: showDropDown ? "chevron.up" : "chevron.down")
						.foregroundColor(.gray)
				}
				.padding(.vertical, 8)
				.padding(.horizontal, 12)
				.background(.white)
				.clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
				.onTapGesture {
					showDropDown.toggle()
				}
				.onChange(of: showDropDown, { _, newValue in
					focusState = newValue ? .category : .session
				})
				.overlay(alignment: .top) {
					dropDownView
				}
			}
		}
		.zIndex(100)
	}
	
	func itemDidSelect(index: Int? = nil) {
		if let index = index {
			selectedIndex = index
			itemDidSelect?(categories[index].id)
		} else {
			itemDidSelect?(categories[selectedIndex].id)
		}
		showDropDown.toggle()
	}
}

extension CategorySelectorView {
	@ViewBuilder
	var dropDownView: some View {
		if showDropDown {
			VStack(spacing: 0) {
				ForEach(Array(categories.enumerated()), id: \.offset) { (index, item) in
					let isSelected = index == selectedIndex
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
			.focused($focusState, equals: .category)
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
				showDropDown = false
				return .handled
			}
			.background(.white)
			.cornerRadius(4)
			.offset(y: 40)
			.shadow(color: .gray, radius: 5, x: 0, y: 2)
		}
	}
}

//#Preview {
//	CategorySelectorView(selectedCategory: .init(id: 0, title: "Category", color: .green))
//}

