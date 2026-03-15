#!/bin/bash

# SuperRadar - Setup Script
# Configura o ambiente local para desenvolvimento

set -e  # Exit on error

echo "🚀 SuperRadar - Setup Script"
echo "=============================="
echo ""

# Check Python version
echo "✓ Verificando Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 não encontrado. Instale Python 3.10+ antes de continuar."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "  Python version: $PYTHON_VERSION"

# Create virtual environment
echo ""
echo "✓ Criando ambiente virtual..."
python3 -m venv venv

# Activate virtual environment
echo "✓ Ativando ambiente virtual..."
source venv/bin/activate

# Install dependencies
echo ""
echo "✓ Instalando dependências..."
cd backend
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

# Install Playwright browsers
echo ""
echo "✓ Instalando Playwright browsers..."
playwright install chromium

cd ..

# Create .env file if it doesn't exist
echo ""
if [ ! -f backend/.env ]; then
    echo "✓ Criando arquivo .env..."
    cp backend/.env.example backend/.env
    echo "⚠️  Edite backend/.env com suas credenciais!"
else
    echo "✓ Arquivo .env já existe"
fi

# Create prints directory
echo ""
echo "✓ Criando diretório de prints..."
mkdir -p backend/prints

echo ""
echo "=============================="
echo "✅ Setup concluído com sucesso!"
echo ""
echo "Próximos passos:"
echo "1. Edite backend/.env com suas credenciais"
echo "2. Execute: python -m app.main"
echo "3. Consulte README.md para mais informações"
echo ""
echo "💡 Para ativar o ambiente novamente:"
echo "   source venv/bin/activate"
