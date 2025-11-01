//
//  ContentView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI

struct ContentView: View {
    @FocusState private var isKeyboardFocused: Bool
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    isKeyboardFocused = false
                }

            VStack(spacing: 0) {
                TopBar()
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .onTapGesture {
                        isKeyboardFocused = false
                    }

                Spacer()
                    .onTapGesture {
                        isKeyboardFocused = false
                    }

                Text("Cogito, ergo sum")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color(red: 26/255, green: 115/255, blue: 232/255))
                    .multilineTextAlignment(.center)
                    .onTapGesture {
                        isKeyboardFocused = false
                    }

                Spacer()
                    .onTapGesture {
                        isKeyboardFocused = false
                    }
                
                BottomBar(isKeyboardFocused: $isKeyboardFocused)
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
    }
}

private struct TopBar: View {
    var body: some View {
        ZStack {
            HStack {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                ProfileAvatar()
            }

            Text("Gemini")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }
}

private struct ProfileAvatar: View {
    var body: some View {
        Circle()
            .strokeBorder(AngularGradient(gradient: Gradient(colors: [
                .red, .orange, .yellow, .green, .blue, .purple, .red
            ]), center: .center), lineWidth: 3)
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .fill(Color(.systemGray6))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    )
                    .padding(4)
            )
    }
}

private struct BottomBar: View {
    @State private var inputText: String = ""
    @FocusState.Binding var isKeyboardFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("connect any model, chat anywhere")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                
                TextEditor(text: $inputText)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .focused($isKeyboardFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 20, maxHeight: 100)
            }

            HStack(spacing: 14) {
                RoundIcon(systemName: "plus")
                RoundIcon(systemName: "slider.horizontal.3")

                Spacer()

                CapsuleButton(title: "2.5 Pro")
                RoundButton(systemName: "mic.fill")
                RoundButton(systemName: "sparkles")
            }
        }
        .padding(.top, 28)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .background(
            GeometryReader { geometry in
                UnevenRoundedRectangle(cornerRadii: .init(
                    topLeading: 32,
                    topTrailing: 32
                ), style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.12), radius: 16, x: 0, y: 8)
                    .frame(height: geometry.size.height + geometry.safeAreaInsets.bottom)
                    .offset(y: 0)
            }
        )
    }
}

private struct RoundIcon: View {
    var systemName: String

    var body: some View {
        Circle()
            .fill(Color(.systemGray6))
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
            )
    }
}

private struct CapsuleButton: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(.systemGray6))
            )
            .foregroundStyle(.primary)
    }
}

private struct RoundButton: View {
    var systemName: String

    var body: some View {
        Circle()
            .fill(Color(.systemGray6))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
            )
    }
}

#Preview {
    ContentView()
}
