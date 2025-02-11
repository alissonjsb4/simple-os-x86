void editor() {
    // Função simples para simular um editor de texto
    char buffer[256];
    int pos = 0;

    while (1) {
        char c = getchar();
        if (c == 0x08 && pos > 0) { // Backspace
            pos--;
            buffer[pos] = '\0';
        } else if (c == 0x13) { // Ctrl+S (salvar)
            print("\nText saved.\n");
            return;
        } else {
            buffer[pos] = c;
            pos++;
        }
    }
}
