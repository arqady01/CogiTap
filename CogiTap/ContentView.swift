//
//  ContentView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                TopBar()
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer()

                Text("Cogito, ergo sum")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color(red: 26/255, green: 115/255, blue: 232/255))
                    .multilineTextAlignment(.center)

                Spacer()

                BottomBar()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("问问 Gemini")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                RoundIcon(systemName: "plus")
                RoundIcon(systemName: "slider.horizontal.3")

                Spacer()

                CapsuleButton(title: "2.5 Pro")
                RoundButton(systemName: "mic.fill")
                RoundButton(systemName: "sparkles")
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.12), radius: 16, x: 0, y: 8)
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
