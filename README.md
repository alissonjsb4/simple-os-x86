# Simple OS – Sistema Operacional Simples em Assembly

O **Simple OS** é um projeto desenvolvido no âmbito da disciplina de Microprocessadores da **Universidade Federal do Ceará (UFC)**, ministrada pelo professor **Nícolas de Araújo Moreira**, no semestre **2024.2**. Este projeto foi realizado em equipe pelos seguintes alunos:

- **Alisson Jaime Sales Barros**
- **Danilo Bezerra Vieira**
- **Francisco Vinicius Castro Silveira**
- **José Ferreira Lessa**
- **Matheus Rocha Gomes da Silva**
- **Nataniel Marques Viana Neto**
- **Thiago Siqueira de Sousa**

## Objetivo

O objetivo do **Simple OS** é demonstrar os conceitos fundamentais de um sistema operacional (SO) simples, implementado inteiramente em **Assembly** para a arquitetura **x86** no modo real de 16 bits. O sistema é composto por:

- **Bootloader**: Responsável pela inicialização do sistema.
- **Kernel**: Fornece um prompt de comando interativo.
- **Editor de Texto**: Permite a criação, edição e salvamento de arquivos.

O projeto ilustra a interação direta com o hardware por meio das **interrupções do BIOS**, servindo como uma ferramenta educacional para o estudo de sistemas operacionais e programação de baixo nível.

## Sumário

- [:information_source: Visão Geral](#visão-geral)
- [:package: Arquitetura e Componentes](#arquitetura-e-componentes)
  - [Bootloader](#bootloader)
  - [Kernel](#kernel)
  - [Editor de Texto](#editor-de-texto)
  - [Script de Build](#script-de-build)
- [:gear: Detalhes Técnicos](#detalhes-técnicos)
- [:clipboard: Requisitos](#requisitos)
- [:rocket: Instruções de Build e Execução](#instruções-de-build-e-execução)
- [:hammer_and_wrench: Estrutura Técnica](#estrutura-técnica)
- [:warning: Limitações e Melhorias Futuras](#limitações-e-melhorias-futuras)
- [:handshake: Contribuições](#contribuições)
- [:scroll: Licença](#licença)

---

## Visão Geral

O projeto **Simple OS** tem como objetivo demonstrar o funcionamento básico de um sistema operacional. Por meio deste sistema, o usuário pode:

- Inicializar o sistema por meio de um bootloader.
- Executar um kernel que fornece um prompt de comando interativo.
- Utilizar um editor de texto simples para criar, editar e salvar arquivos diretamente no disco, usando operações de leitura e escrita via BIOS.

Esta implementação é ideal para estudantes, pesquisadores e entusiastas que desejam compreender os conceitos de boot, carregamento de kernel e operações de baixo nível em um ambiente de 16 bits.

---

## Arquitetura e Componentes

### Bootloader

- **Localização e Função**:  
  - O bootloader está armazenado no disco rígido, quando o PC é ligado, a BIOS assume o controle primeiro. Ela      procura um disco de boot (dispositivo de armazenamento que contém um sistema operacional ou pelo menos um 
    bootloader como HD, SSD, pendrive, etc), ao encontrar ele, a BIOS vai ler o primeiro disco do setor (512 
    bytes), onde reside o bootloader, e vai executar seu código que é o primeiro executado pelo sistema. O   
    bootloader então carrega o sistema operacional na memória RAM  e transfere o controle para ele.
- **Responsabilidades**:
  - Desabilitar interrupções e configurar os registradores iniciais.
  - Carregar o kernel e o editor de texto a partir de setores específicos do disco.
  - Exibir mensagens de status e tratar erros de leitura de disco.
- **Técnicas Utilizadas**:
  - Uso de interrupções do BIOS, como `int 0x13` para operações de disco e `int 0x10` para saída de vídeo.
  - Definição da posição do código com a diretiva `[ORG 0x7C00]`. É um padrão definido pelos fabricantes de PCs.

### Kernel

- **Localização e Função**:
  - Carregado pelo bootloader no endereço de memória `0x1000`.
  - Fornece um prompt de comando interativo para o usuário e gerencia a transição entre os modos de operação.
- **Responsabilidades e Funções do Kernel**:
  - **Configuração do Ambiente**: Inicializa os segmentos, a pilha e posiciona o cursor na tela.
  - **Interface de Linha de Comando (CLI)**:  
    - Exibe mensagens e opções de comando.
    - Processa comandos do usuário:
      - `e`: Inicia o editor de texto.
      - `r`: Reinicia o sistema.
      - `v`: Visualiza arquivos salvos, permitindo a seleção de um arquivo para exibição completa.
  - **Gerenciamento de Disco**:
    - Realiza leitura de setores utilizando a interrupção `int 0x13`.
    - Gerencia um contador de arquivos para facilitar a navegação e visualização dos dados salvos.
- **Operações de Disco**:
  - Lê setores específicos para carregar o editor e recuperar os arquivos salvos.
  - Atualiza o contador de arquivos, armazenado em um setor reservado.

### Editor de Texto

- **Localização e Função**:
  - Carregado no endereço de memória `0x2000`.
  - Permite a entrada e edição de textos, possibilitando salvar os arquivos editados.
- **Funcionalidades**:
  - Suporte a backspace, nova linha (Enter) e salvamento de conteúdo (Ctrl+S).
  - Exibição de um cabeçalho com instruções de uso.
  - Salvamento de arquivos em setores consecutivos, com atualização de um contador de arquivos.
- **Interação com o Sistema**:
  - Utiliza interrupções de vídeo e disco para exibir e salvar o conteúdo.
  - Permite retornar ao kernel ao pressionar a tecla Esc.

### Script de Build

- **Objetivo**:
  - Automatizar a compilação dos arquivos Assembly e a criação da imagem de disco (`disk.img`).
- **Funcionalidades**:
  - Compila os arquivos `bootloader.asm`, `kernel.asm` e `editor.asm` utilizando o NASM.
  - Verifica se os binários gerados estão dentro dos tamanhos limite (bootloader: 512 bytes; kernel: 2048 bytes; editor: 1536 bytes).
  - Cria uma imagem de disco com 100 setores e posiciona os binários em seus respectivos setores.
  - Exibe instruções para executar o sistema em um emulador, como o QEMU.

---

## Detalhes Técnicos

- **Modo Real de 16 bits**:  
  Toda a execução ocorre no modo real, utilizando as restrições e capacidades dos registradores de 16 bits.

- **Interrupções Utilizadas**:
  - **`int 0x10`**: Gerencia operações de vídeo, como a impressão de caracteres, limpeza da tela e movimentação do cursor.
  - **`int 0x13`**: Responsável por operações de leitura e escrita no disco, fundamentais para o carregamento do kernel, do editor e dos arquivos.
  - **`int 0x16`**: Captura a entrada do teclado para interatividade.

- **Carregamento e Gerenciamento de Arquivos**:
  - O sistema utiliza setores específicos do disco para armazenar e recuperar arquivos.
  - O editor salva textos em setores consecutivos e atualiza um contador de arquivos, permitindo ao kernel gerenciar a navegação pelos arquivos salvos.

- **Manipulação de Buffer**:
  - Rotinas de limpeza de buffer são implementadas tanto no kernel quanto no editor para evitar a interferência de dados residuais.
  
- **Conversão e Exibição de Dados**:
  - Funções para converter números em formato de dois dígitos (com preenchimento de zero para valores menores que 10) são utilizadas para exibir números de maneira padronizada na tela.

---

## Requisitos

- **NASM**: Utilizado para compilar os arquivos Assembly.
- **Bash**: Necessário para executar o script de build.
- **dd**: Utilitário para a criação e manipulação da imagem de disco (disponível em sistemas Unix-like).
- **QEMU**: Emulador de hardware, como o `qemu-system-x86_64`, para testar e emular o Simple OS.

---

## Instruções de Build e Execução

### Compilação e Criação da Imagem

1. **Clone o Repositório**:
    ```bash
    git clone https://github.com/seu-usuario/simple-os.git
    cd simple-os
    ```

2. **Torne o Script Executável (se necessário)**:
    ```bash
    chmod +x script
    ```

3. **Execute o Script de Build**:
    ```bash
    ./script
    ```
    O script realiza as seguintes etapas:
    - **Compilação**: Converte os arquivos `bootloader.asm`, `kernel.asm` e `editor.asm` em binários.
    - **Verificação**: Garante que os binários não excedam os limites de tamanho definidos.
    - **Criação da Imagem de Disco**: Gera um arquivo `disk.img` com 100 setores, posicionando os binários nos setores corretos.

### Execução com QEMU

Após a compilação, inicie o Simple OS em um emulador QEMU com o comando:
```bash
qemu-system-x86_64 -drive format=raw,file=disk.img
```
Esta instrução iniciará a emulação, permitindo que você teste e interaja com o sistema.

---

## Estrutura Técnica

### Layout do Disco
| Setor | Conteúdo               | Tamanho      | Endereço Memória |
|-------|------------------------|--------------|------------------|
| 0     | Bootloader             | 512 bytes    | 0x7C00           |
| 1-2   | Livre                  | -            | -                |
| 3-6   | Kernel                 | 2KB          | 0x1000           |
| 7-9   | Editor                 | 1.5KB        | 0x2000           |
| 10+   | Dados do Usuário       | 512B/arquivo | 0x3000           |

---

## Limitações e Melhorias Futuras

### Tratamento de Erros
- O tratamento atual de erros é básico. Futuras versões poderão incluir mecanismos mais robustos para lidar com falhas de leitura e escrita no disco, bem como notificações mais detalhadas ao usuário.

### Funcionalidades do Editor
- **Edição Avançada**: Implementar navegação entre linhas, suporte à edição de múltiplas linhas e funcionalidades de corte/colagem.
- **Sistema de Arquivos**: Desenvolver um sistema de arquivos mais sofisticado para organizar e gerenciar os textos salvos, permitindo melhor recuperação e manipulação dos dados.

### Gerenciamento de Memória
- Evoluir do modo real para modos protegidos ou até mesmo para arquiteturas de 32/64 bits, possibilitando um gerenciamento de memória mais robusto e a execução de aplicações mais complexas.

### Interface do Usuário
- Melhorar a interface textual e, futuramente, implementar uma interface gráfica para proporcionar uma experiência de usuário mais rica e intuitiva.

---

## Contribuições

Contribuições para o projeto são muito bem-vindas. Para contribuir:

- Faça um **fork** do repositório.
- Crie uma **branch** para implementar suas alterações.
- Envie um **pull request** para revisão e discussão.

---

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE). Sinta-se à vontade para utilizar, modificar e distribuir o código conforme os termos desta licença.

