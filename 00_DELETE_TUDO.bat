@echo off
REM ============================================================================
REM SISTEMA AUTÔNOMO - INICIALIZADOR (Windows Batch)
REM ============================================================================
REM Duplo clique neste arquivo para iniciar o watcher automático
REM ============================================================================

setlocal enabledelayedexpansion

REM Detecs a pasta do script
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

REM Título da janela
title SISTEMA AUTÔNOMO - Prime Fazendas [ATIVO]

REM Mensagem de boas-vindas
cls
echo.
echo ╔═══════════════════════════════════════════════════════════════════════════════╗
echo ║                   🚀 SISTEMA AUTÔNOMO - PRIME FAZENDAS                       ║
echo ║                                                                               ║
echo ║  Status: ATIVO E MONITORANDO ✅                                              ║
echo ║  Pasta: %SCRIPT_DIR%
echo ║                                                                               ║
echo ║  ℹ️  Deixe esta janela aberta (pode minimizar)                              ║
echo ║  ℹ️  Qualquer mudança será detectada em ~45 segundos                        ║
echo ║                                                                               ║
echo ╚═══════════════════════════════════════════════════════════════════════════════╝
echo.
echo Iniciando PowerShell com script de monitoramento...
echo.

REM Executar PowerShell com o script de watcher
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%INICIAR_WATCH.ps1"

REM Se PowerShell fechar, dar opção de reiniciar
echo.
echo Watcher encerrado.
pause
