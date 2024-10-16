//
//  BottomBar.swift
//  CineGuide
//
//  Created by Etudiant on 17/09/2024.
//

import SwiftUI

struct BottomBar: View {
    let currentPage: Int
    let totalPages: Int
    let onPageChange: (Int) -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())  // Supprimer le style par défaut du bouton
            
            Spacer()
            
            let lowerBound = max(1, currentPage - 1)
            let upperBound = min(totalPages, currentPage + 1) <= totalPages - 1 ? currentPage + 1 : currentPage + 2
                        
            // Afficher les boutons pour chaque page
            ForEach(lowerBound...upperBound, id: \.self) { page in
                Button(action: {
                    onPageChange(page)
                }) {
                    Text("\(page)")
                        .padding()
                        .background(currentPage == page ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())  // Supprimer le style par défaut du bouton
        }
        .padding()
        .background(Color.white)  // Fond blanc pour la barre
        .cornerRadius(12)  // Coins arrondis pour la barre
        .shadow(radius: 5)  // Ombre douce pour la barre
        .padding([.leading, .trailing], 20)  // Ajouter du padding pour éviter que la barre touche les bords
    }
}
