Passos para aplica��o:

1. Aplicar dicion�rio de dados:

IMPORTANTE:
Fazer Backup geral de banco de dados (pois dicionario est� nele)
Antes de aplicar, revisar nos arquivos e ajustar se necess�rio:
- Campos que compoem filial no conteudo:
	- U56_PREFIX = Tamanho campo Filial + 1 
	- U57_PREFIX = Tamanho campo Filial + 1 
	- E1_XCODBAR = U57_PREFIX + U57_CODIGO (8) + U57_PARCEL (3)
	- UF2_CODBAR = U57_PREFIX + U57_CODIGO (8) + U57_PARCEL (3)
	- EF_XCODBAR = U57_PREFIX + U57_CODIGO (8) + U57_PARCEL (3)
	- U0H_CODBAR = U57_PREFIX + U57_CODIGO (8) + U57_PARCEL (3)
- Campo A3_RFID caso use mais de um identifid por frentista

1.1. Descompactar arquivos de dicionario em uma pasta
1.2. Executar pelo smartclient a fun��o U_UPDPOSTO em modo exclusivo
1.3. Selecionar o grupo de empresas a aplicar o dicionario
1.4. Selecionar a pasta onde est�o os arquivos de dicionario (fazer dois processamentos: Customizado e Padr�o)
1.5. Aguardar processamento e conferir ao termino se tudo processou corretamente.

2. Aplicar patch
tttm120_2210_posto_completo.ptm

3. Aplicar rdmakes atualizados
Obs.: N�o teve mudan�as daquele ultimo que te mandei

4. Revisar pontos de entrada
Obs.: N�o teve mudan�as daquele ultimo que te mandei
