// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import SwiftUI

/// The search-and-select overlay: search field with instant focus + a filtered, navigable list.
struct OverlayView: View {
    @ObservedObject var model: OverlayModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            resultsList
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .frame(width: 640, height: 420)
        .onAppear {
            searchFocused = true
            model.reload()
        }
        // Re-focus on every open (the view is reused).
        .onChange(of: model.focusRequest) { _, _ in
            searchFocused = true
        }
        // Live filtering while typing.
        .onChange(of: model.searchText) { _, _ in
            model.resetSelection()
            model.reload()
        }
        .onKeyPress(.downArrow) { model.moveSelection(1); return .handled }
        .onKeyPress(.upArrow) { model.moveSelection(-1); return .handled }
        .onExitCommand { model.onClose?() }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search clipboard…", text: $model.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .focused($searchFocused)
                .onSubmit { model.selectCurrent() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Results list

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // Deliberately VStack instead of LazyVStack: if the list is first created
                // empty (in a hidden or first-shown panel) and then populated, a LazyVStack
                // does not materialize the rows afterwards → empty list on first open. With
                // the few entries here, eager rendering is not a concern.
                VStack(spacing: 2) {
                    if model.items.isEmpty {
                        Text("No entries")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                            OverlayRow(
                                item: item,
                                index: index,
                                isSelected: index == model.selectionIndex
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                model.selectionIndex = index
                                model.selectCurrent()
                            }
                        }
                    }
                }
                .padding(8)
            }
            .onChange(of: model.selectionIndex) { _, newValue in
                guard model.items.indices.contains(newValue) else { return }
                withAnimation(.linear(duration: 0.05)) {
                    // Scroll via the stable item identity (not the index), so the ForEach
                    // identity stays consistent.
                    proxy.scrollTo(model.items[newValue].id, anchor: .center)
                }
            }
        }
    }
}

/// A single row in the results list.
private struct OverlayRow: View {
    let item: ClipItem
    let index: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Quick-paste number for the first 6 entries.
            if index < 6 {
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .frame(width: 18, height: 18)
                    .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(.secondary)
            } else {
                Color.clear.frame(width: 18, height: 18)
            }

            icon

            Text(item.preview)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            if item.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
        )
    }

    @ViewBuilder
    private var icon: some View {
        switch item.kind {
        case .text:
            Image(systemName: "text.alignleft").foregroundStyle(.secondary)
        case .image:
            if let data = item.imageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Image(systemName: "photo").foregroundStyle(.secondary)
            }
        case .file:
            Image(systemName: "doc").foregroundStyle(.secondary)
        }
    }
}
