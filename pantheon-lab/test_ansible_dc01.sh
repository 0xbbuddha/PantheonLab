#!/bin/bash

echo "🔧 Test des playbooks Ansible pour DC01"
echo "======================================="

# Vérifier que DC01 est en marche
echo "🔍 Vérification de l'état de pantheon-dc01..."
cd vagrant
VM_STATUS=$(vagrant status pantheon-dc01 | grep pantheon-dc01 | awk '{print $2}')

if [ "$VM_STATUS" != "running" ]; then
    echo "❌ pantheon-dc01 n'est pas en cours d'exécution (état: $VM_STATUS)"
    echo "💡 Lancez d'abord: ./test_dc01.sh ou vagrant up pantheon-dc01"
    exit 1
fi

echo "✅ pantheon-dc01 est en cours d'exécution"
echo ""

# Revenir au répertoire racine
cd ..

# Test de connectivité
echo "🌐 Test de connectivité WinRM..."
ansible -i ansible/inventory/vagrant_inventory.yml pantheon-dc01 -m win_ping -e "target_host=pantheon-dc01" -e "server_type=dc01" -e "data_path=../vars"

if [ $? -ne 0 ]; then
    echo "❌ Impossible de se connecter à pantheon-dc01 via WinRM"
    echo "💡 Vérifiez que WinRM est configuré sur la VM"
    exit 1
fi

echo "✅ Connectivité WinRM OK"
echo ""

# Test du chargement des variables
echo "🔧 Test du chargement des variables de configuration..."
ansible-playbook -i ansible/inventory/vagrant_inventory.yml ansible/playbooks/windows_config.yml -e "target_host=pantheon-dc01" -e "server_type=dc01" -e "data_path=../vars" --check

if [ $? -eq 0 ]; then
    echo "✅ Configuration des variables réussie!"
    echo ""
    echo "🚀 Vous pouvez maintenant lancer les autres playbooks:"
    echo "   - ansible-playbook -i ansible/inventory/vagrant_inventory.yml ansible/playbooks/windows_main.yml -e target_host=pantheon-dc01 -e server_type=dc01 -e data_path=../vars"
    echo ""
    echo "📝 Ou tester des playbooks spécifiques:"
    echo "   - ansible-playbook -i ansible/inventory/vagrant_inventory.yml ansible/playbooks/windows_adds.yml -e target_host=pantheon-dc01 -e server_type=dc01 -e data_path=../vars"
else
    echo "❌ Erreur dans la configuration des variables"
    echo "🔍 Vérifiez les fichiers dc.json et windows_common.yml"
    exit 1
fi 