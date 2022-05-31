//
//  ActionSheet.swift
//  Action Sheet Demo
//
//  Created by Josh Arnold on 5/30/22.
//

import SwiftUI

// MARK: - View

struct ActionSheet<Content: View>: View {
    
    // MARK: - Constants
    
    private let dimBackgroundAmount = 0.5
    
    private let requiredDismissVelocity: CGFloat = 6
    
    private let fadeDimBackgroundTolerance: CGFloat = 120

    // MARK: - Properties
    
    @Binding var isPresented: Bool
    
    @ViewBuilder let content: Content
    
    @State private var dimOpacity: Double = 0.0

    @State private var dragOffset: Double = UIScreen.main.bounds.height
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                Spacer()
                VStack {
                    Divider()
                    content
                    Spacer()
                        .frame(height: max(-dragOffset, .zero)) // Allows for "stretching the view
                }
                .background(.background)
                .offset(x: .zero, y: max(dragOffset, .zero)) // Allows for dragging to dismiss
            }
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        dragOffset = value.translation.height
                        dimOpacity = dragOffset > 0 ? dimBackgroundAmount * (1 - (dragOffset / fadeDimBackgroundTolerance)) : dimBackgroundAmount
                    })
                    .onEnded({ value in
                        let velocity = value.predictedEndLocation.y - value.location.y
                        if velocity > requiredDismissVelocity {
                            dismissActionSheet(actionSheetHeight: proxy.size.height)
                        } else {
                            resetActionSheet()
                        }
                    })
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Rectangle()
                    .background(Color.black)
                    .opacity(dimOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissActionSheet(actionSheetHeight: proxy.size.height)
                    }
            )
            .onAppear {
                if isPresented {
                    showActionSheet(actionSheetHeight: proxy.size.height)
                } else {
                    dismissActionSheet(actionSheetHeight: proxy.size.height, animated: false)
                }
            }
            .onChange(of: isPresented) { newValue in
                if newValue {
                    showActionSheet(actionSheetHeight: proxy.size.height)
                } else {
                    dismissActionSheet(actionSheetHeight: proxy.size.height)
                }
            }
        }
    }

    // MARK: - Helper
    
    /// Presents the action sheet
    private func showActionSheet(actionSheetHeight: Double) {
        withAnimation(.easeOut) {
            dragOffset = .zero
            dimOpacity = dimBackgroundAmount
        }
    }
    
    /// Hides the action sheet
    private func dismissActionSheet(actionSheetHeight: Double, animated: Bool = true) {
        withAnimation(animated ? .easeIn : .none) {
            dragOffset = actionSheetHeight
            dimOpacity = .zero
            isPresented = false
        }
    }
    
    /// Resets the action sheet back to its normal, visible position
    private func resetActionSheet() {
        withAnimation(.spring()) {
            dragOffset = 0.0
            dimOpacity = dimBackgroundAmount
        }
    }
}

// MARK: - View Modifier

struct ActionSheetModifier<V: View>: ViewModifier {
    
    @Binding var isPresented: Bool
    
    @ViewBuilder var actionSheetContent: V
    
    func body(content: Content) -> some View {
        ZStack {
            content.allowsHitTesting(!isPresented)
            ActionSheet(isPresented: $isPresented) {
                actionSheetContent
            }
            .allowsHitTesting(isPresented)
        }
    }
}

extension View {
    func actionSheet<V: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> V
    ) -> some View {
        modifier(
            ActionSheetModifier(
                isPresented: isPresented,
                actionSheetContent: {
                    content()
                }
            )
        )
    }
}

// MARK: - Previews

struct ActionSheet_Previews: PreviewProvider {
    
    static var previews: some View {
        ActionSheet(isPresented: .constant(true)) {
            Image(systemName: "questionmark")
                .fixedSize()
                .frame(height: 200)
        }
    }
}
