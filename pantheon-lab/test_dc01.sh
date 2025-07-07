#!/bin/bash

echo "🏛️  Script de test pour DC01 uniquement"
echo "========================================"

# Aller dans le répertoire vagrant
cd vagrant

# Vérifier et détruire DC01 s'il existe
echo "🔥 Destruction de pantheon-dc01..."
vagrant destroy pantheon-dc01 -f

# Lancer uniquement DC01
echo "🚀 Lancement de pantheon-dc01..."
vagrant up pantheon-dc01

# Vérifier le statut
if [ $? -eq 0 ]; then
    echo "✅ pantheon-dc01 déployé avec succès!"
    echo ""
    echo "📊 Statut des VMs:"
    vagrant status
    echo ""
    echo "🔗 Connexion RDP disponible sur: localhost:53389"
    echo "👤 Utilisateur: Administrator"
    echo "🔑 Mot de passe: Pantheon@2024"
else
    echo "❌ Erreur lors du déploiement de pantheon-dc01"
    exit 1
fi 