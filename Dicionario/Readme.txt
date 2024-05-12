Passos para aplicação:

1. Aplicar dicionário de dados:

IMPORTANTE:
Fazer Backup geral de banco de dados (pois dicionario está nele)
Antes de aplicar, revisar nos arquivos e ajustar se necessário:
- Campos que compoem filial no conteudo:
	- U56_PREFIX = Tamanho campo Filial + 1 
	- U57_PREFIX = Tamanho campo Filial + 1 
	- E1_XCODBAR = U57_PREFIX + U57_CODIGO (8) + U57_PARCEL (3)
	- UF2_CODBAR = U57_PREFIX + U57_CODIGO (8) + U57_PARCEL (3)
	- EF_XCODBAR = U57_PREFIX + U57_CODIGO (8) + U57_PARCEL (3)
	- U0H_CODBAR = U57_PREFIX + U57_CODIGO (8) + U57_PARCEL (3)
- Campo A3_RFID caso use mais de um identifid por frentista

1.1. Descompactar arquivos de dicionario em uma pasta
1.2. Executar pelo smartclient a função U_UPDPOSTO em modo exclusivo
1.3. Selecionar o grupo de empresas a aplicar o dicionario
1.4. Selecionar a pasta onde estão os arquivos de dicionario (fazer dois processamentos: Customizado e Padrão)
1.5. Aguardar processamento e conferir ao termino se tudo processou corretamente.

2. Aplicar patch
tttm120_2210_posto_completo.ptm

3. Aplicar rdmakes atualizados
Obs.: Não teve mudanças daquele ultimo que te mandei

4. Revisar pontos de entrada
Obs.: Não teve mudanças daquele ultimo que te mandei
