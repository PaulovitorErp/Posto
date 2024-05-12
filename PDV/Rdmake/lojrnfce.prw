#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FWPRINTSETUP.CH"
#INCLUDE "RPTDEF.CH"

//Modalidades de TEF dispon�veis no sistema
#DEFINE TEF_SEMCLIENT_DEDICADO  "2"         // Utiliza TEF Dedicado Troca de Arquivos                      
#DEFINE TEF_COMCLIENT_DEDICADO  "3"			// Utiliza TEF Dedicado com o Client
#DEFINE TEF_DISCADO             "4"			// Utiliza TEF Discado 
#DEFINE TEF_LOTE                "5"			// Utiliza TEF em Lote
#DEFINE TEF_CLISITEF			"6"			// Utiliza a DLL CLISITEF
#DEFINE TEF_CENTROPAG			"7"			// Utiliza a DLL tef mexico


// Possibilidades de uso do parametro MV_AUTOCOM
#DEFINE DLL_SIGALOJA			0			// Usa somente perif�ricos da SIGALOJA.DLL
#DEFINE DLL_SIGALOJA_AUTOCOM	1			// Usa perif�ricos da SIGALOJA.DLL e da AUTOCOM
#DEFINE DLL_AUTOCOM				2			// Usa somente perif�ricos da AUTOCOM

// Retornos da GetRemoteType()
#DEFINE REMOTE_JOB	 			-1			// N�o h� Remote, executando Job
#DEFINE REMOTE_DELPHI			0			// O Remote est� em Windows Delphi
#DEFINE REMOTE_QT				1			// O Remote est� em Windows QT
#DEFINE REMOTE_LINUX			2			// O Remote est� em Linux
#DEFINE REMOTE_HTML				5			// N�o h� Remote, executando HTML

// Tipos de equipamentos
#DEFINE EQUIP_IMPFISCAL			1
#DEFINE EQUIP_PINPAD			2
#DEFINE EQUIP_CMC7				3
#DEFINE EQUIP_GAVETA			4
#DEFINE EQUIP_IMPCUPOM			5
#DEFINE EQUIP_LEITOR			6
#DEFINE EQUIP_BALANCA			7
#DEFINE EQUIP_DISPLAY			8
#DEFINE EQUIP_IMPCHEQUE			9
#DEFINE EQUIP_IMPNAOFISCAL		10			

// Qual DLL o Equipamento esta utilizando
#DEFINE EQUIP_DLL_NENHUM		0			// O equipamento nao foi configurado 
#DEFINE EQUIP_DLL_AUTOCOM		1			// O equipamento foi configurado para utilizar a AUTOCOM
#DEFINE EQUIP_DLL_SIGALOJA		2			// O equipamento foi configurado para utilizar a SIGALOJA

//**************************************************************************************************//
//Tags para impress�o em Impressoras Fiscal e N�o-Fiscal
//
//	NOTAS:
//		- essas tags foram baseadas no modulo Daruma N�o-Fiscal
// 		- ao adicionar uma tag aqui inserir na fun��es da sigaloja, 
//		totvsapi e autocom para tratar as tags por modelo de ECF, 
//		nos fontes dos modelos e no LOJA1305 que trata da remo��o da tag nao utilizada
//**************************************************************************************************//
#DEFINE TAG_ESC			CHR(27)
#DEFINE TAG_NEGRITO_INI	 "<b>"	//Inicia Texto em Negrito
#DEFINE TAG_NEGRITO_FIM	"</b>" //finaliza texto em negrito
#DEFINE TAG_ITALICO_INI	"<i>"	//it�lico
#DEFINE TAG_ITALICO_FIM	"</i>" //it�lico
#DEFINE TAG_CENTER_INI	"<ce>"	//centralizado
#DEFINE TAG_CENTER_FIM	"</ce>"//centralizado
#DEFINE TAG_SUBLI_INI	 "<s>"	//sublinhado
#DEFINE TAG_SUBLI_FIM 	"</s>"	//sublinhado
#DEFINE TAG_EXPAN_INI 	"<e>"	//expandido
#DEFINE TAG_EXPAN_FIM	 "</e>"	//expandido
#DEFINE TAG_CONDEN_INI	"<c>"	//condensado
#DEFINE TAG_CONDEN_FIM	"</c>"	//condensado
#DEFINE TAG_NORMAL_INI	"<n>"	//normal 
#DEFINE TAG_NORMAL_FIM	"</n>"	//normal
#DEFINE TAG_PULALI_INI	"<l>"	//pula 1 linha
#DEFINE TAG_PULALI_FIM	"</l>"	//pula 1 linha
#DEFINE TAG_PULANL_INI	"<sl>"	//pula NN linhas
#DEFINE TAG_PULANL_FIM	"</sl>"//pula NN linha
#DEFINE TAG_RISCALN_INI	"<tc>"	//risca a linha caracter especifico
#DEFINE TAG_RISCALN_FIM	"</tc>"
#DEFINE TAG_TABS_INI		"<tb>"	//tabula��o
#DEFINE TAG_TABS_FIM		"</tb>"
#DEFINE TAG_DIREITA_INI	"<ad>" //alinhado a direita
#DEFINE TAG_DIREITA_FIM	"</ad>"
#DEFINE TAG_ELITE_INI	 "<fe>"	//habilita fonte elite
#DEFINE TAG_ELITE_FIM 	"</fe>"
#DEFINE TAG_TXTEXGG_INI	"<xl>"	//habilita texto extra grande
#DEFINE TAG_TXTEXGG_FIM	"</xl>"
#DEFINE TAG_GUIL_INI		"<gui>"//ativa guilhotina
#DEFINE TAG_GUIL_FIM		"</gui>"
#DEFINE TAG_EAN13_INI 	"<ean13>"	//codigo de barra ean13
#DEFINE TAG_EAN13_FIM	 "</ean13>"
#DEFINE TAG_EAN8_INI		"<ean8>"	//codigo de barra ean8
#DEFINE TAG_EAN8_FIM		"</ean8>"
#DEFINE TAG_UPCA_INI		"<upc-a>" //codigo de barras upc-a
#DEFINE TAG_UPCA_FIM		"</upc-a>"
#DEFINE TAG_CODE39_INI	"<code39>"//codigo de barras CODE39
#DEFINE TAG_CODE39_FIM	"</code39>"
#DEFINE TAG_CODE93_INI	"<code93>" //codigo de barras CODE93
#DEFINE TAG_CODE93_FIM	"</code93>"
#DEFINE TAG_CODABAR_INI	"<codabar>"//codigo de barras CODABAR
#DEFINE TAG_CODABAR_FIM	"</codabar>"
#DEFINE TAG_MSI_INI		"<msi>" //codigo de barras MSI
#DEFINE TAG_MSI_FIM		"</msi>"
#DEFINE TAG_CODE11_INI	"<code11>"//codigo de barras CODE11
#DEFINE TAG_CODE11_FIM	"</code11>"
#DEFINE TAG_PDF_INI		"<pdf>" //codigo de barras PDF
#DEFINE TAG_PDF_FIM		"</pdf>"
#DEFINE TAG_COD128_INI	"<code128>" //codigo de barras CODE128
#DEFINE TAG_COD128_FIM	"</code128>"
#DEFINE TAG_I2OF5_INI	 "<i2of5>" //codigo I2OF5
#DEFINE TAG_I2OF5_FIM 	"</i2of5>"
#DEFINE TAG_S2OF5_INI 	"<s2of5>" //codigo S2OF5
#DEFINE TAG_S2OF5_FIM	 "</s2of5>"
#DEFINE TAG_QRCODE_INI	"<qrcode>"	//codigo do tipo QRCODE
#DEFINE TAG_QRCODE_FIM	"</qrcode>"
#DEFINE TAG_BMP_INI		"<bmp>" //imprimi logotipo carregado
#DEFINE TAG_BMP_FIM		"</bmp>"
#DEFINE TAG_NIVELQRCD_INI "<correcao>" // nivel de corre��o do QRCode
#DEFINE TAG_NIVELQRCD_FIM "</correcao>"


#DEFINE MTAG_NEGRITO_INI	 TAG_ESC+"E"	//Inicia Texto em Negrito
#DEFINE MTAG_NEGRITO_FIM	 TAG_ESC+"F" //finaliza texto em negrito
#DEFINE MTAG_ITALICO_INI	TAG_ESC+"41"	//it�lico
#DEFINE MTAG_ITALICO_FIM TAG_ESC+"40" //it�lico
#DEFINE MTAG_CENTER_INI	TAG_ESC+"j1"	//centralizado
#DEFINE MTAG_CENTER_FIM	TAG_ESC+"j0"//centralizado
#DEFINE MTAG_SUBLI_INI	TAG_ESC+"-1"	//sublinhado
#DEFINE MTAG_SUBLI_FIM 	TAG_ESC+"-0"	//sublinhado
#DEFINE MTAG_EXPAN_INI 	TAG_ESC+"W1"	//expandido
#DEFINE MTAG_EXPAN_FIM	TAG_ESC+"W0"	//expandido
#DEFINE MTAG_CONDEN_INI	CHR(15)	//condensado
#DEFINE MTAG_CONDEN_FIM	CHR(18)	//condensado
#DEFINE MTAG_NORMAL_INI	CHR(20)	//normal 
#DEFINE MTAG_NORMAL_FIM	""	//normal
#DEFINE MTAG_PULALI_INI	CHR(10)	//pula 1 linha
#DEFINE MTAG_PULALI_FIM	""	//pula 1 linha
#DEFINE MTAG_PULANL_INI	TAG_ESC+"f1"	//pula NN linhas
#DEFINE MTAG_PULANL_FIM	""//pula NN linha
#DEFINE MTAG_RISCALN_INI	""	//risca a linha caracter especifico
#DEFINE MTAG_RISCALN_FIM	""
#DEFINE MTAG_TABS_INI		TAG_ESC+"B"	//tabula��o
#DEFINE MTAG_TABS_FIM		TAG_ESC+"B"
#DEFINE MTAG_DIREITA_INI	TAG_ESC+"j2" //alinhado a direita
#DEFINE MTAG_DIREITA_FIM	TAG_ESC+"j0"
#DEFINE MTAG_ELITE_INI	 TAG_ESC+"!01"	//habilita fonte elite
#DEFINE MTAG_ELITE_FIM 	TAG_ESC+"!00"	
#DEFINE MTAG_TXTEXGG_INI	TAG_ESC+"!41"		//habilita texto extra grande
#DEFINE MTAG_TXTEXGG_FIM	TAG_ESC+"!40"	
#DEFINE MTAG_EAN13_INI 	TAG_ESC+"b1"	//codigo de barra ean13
#DEFINE MTAG_EAN13_FIM	 ""
#DEFINE MTAG_EAN8_INI	TAG_ESC+"b2"	//codigo de barra ean8
#DEFINE MTAG_EAN8_FIM		""
#DEFINE MTAG_UPCA_INI		TAG_ESC+"b8" //codigo de barras upc-a
#DEFINE MTAG_UPCA_FIM		""
#DEFINE MTAG_CODE39_INI	TAG_ESC+"b6"//codigo de barras CODE39
#DEFINE MTAG_CODE39_FIM	""
#DEFINE MTAG_CODE93_INI	TAG_ESC+"b7" //codigo de barras CODE93
#DEFINE MTAG_CODE93_FIM	""
#DEFINE MTAG_CODABAR_INI	TAG_ESC+"b9"//codigo de barras CODABAR
#DEFINE MTAG_CODABAR_FIM	""
#DEFINE MTAG_MSI_INI		TAG_ESC+"b10" //codigo de barras MSI
#DEFINE MTAG_MSI_FIM		""
#DEFINE MTAG_CODE11_INI	TAG_ESC+"b11" //codigo de barras CODE11
#DEFINE MTAG_CODE11_FIM	""
#DEFINE MTAG_PDF_INI		TAG_ESC+CHR(128) //codigo de barras PDF
#DEFINE MTAG_PDF_FIM		""
#DEFINE MTAG_COD128_INI	TAG_ESC+"b5" //codigo de barras CODE128
#DEFINE MTAG_COD128_FIM	""
#DEFINE MTAG_I2OF5_INI	 TAG_ESC+"b4" //codigo I2OF5
#DEFINE MTAG_I2OF5_FIM 	""
#DEFINE MTAG_S2OF5_INI 	TAG_ESC+"b3" //codigo S2OF5
#DEFINE MTAG_S2OF5_FIM	 ""
#DEFINE MTAG_QRCODE_INI	TAG_ESC+Chr(129)	//codigo do tipo QRCODE
#DEFINE MTAG_QRCODE_FIM	""
#DEFINE MTAG_BMP_INI		CHR(22)+"8"//imprimi logotipo carregado
#DEFINE MTAG_BMP_FIM		CHR(22)+"9"
#DEFINE MTAG_NIVELQRCD_INI "" // nivel de corre��o do QRCode
#DEFINE MTAG_NIVELQRCD_FIM ""
#DEFINE MTAG_GUIL_INI	TAG_ESC+"m"//ativa guilhotina
#DEFINE MTAG_GUIL_FIM	""

//Tags disponibilizadas apenas para a bematech
#DEFINE TAG_ITF	 "<itf>"
#DEFINE TAG_ISBN	"<isbn>"
#DEFINE TAG_PLESSEY	 "<plessey>"

//Apenas para DARUMA - o valor dessa tag pode ser 3, 4, 5, 6 ou 7 
#DEFINE TAG_LMODULO_INI "<lmodulo>"
#DEFINE TAG_LMODULO_FIM "</lmodulo>"

//Informa��es de NFCe
#DEFINE _NFCE_AVISO_CONTINGENCIA 	"01" 
#DEFINE _NFCE_ENCONTRAR_IMPRESSORA 	"02" 
#DEFINE _NFCE_TIMEOUT_SERVICO 		"03"
#DEFINE _NFE_MARCA_IMPRESSORA 		"04" 
#DEFINE _NFCE_TIPO_AMBIENTE 		"05"
#DEFINE _NFCE_CODIGO_PARCEIRO 		"06" 
#DEFINE _NFCE_CODIGO_PDV 		"07" 
#DEFINE _NFCE_CODIGO_EMPRESA 		"08"
#DEFINE _NFCE_TOKEN_SEFAZ 		"09" 
#DEFINE _NFCE_AJUSTAR_PAGTO_TOTAL 	"10" 
#DEFINE _NFCE_NUMERACAO_AUTOMATICA 	"11" 
#DEFINE _NFCE_HABILITA_LEI_IMPOSTO 	"12" 
#DEFINE _NFCE_MENSAGEM_COMPLEMENTAR 	"13"
#DEFINE _NFCE_EMIENTE_CNPJ_CPF	 	"14" 
#DEFINE _NFCE_EMITENTE_NOME 		"15" 
#DEFINE _NFCE_EMITENTE_IE 		"16"
#DEFINE _NFCE_EMITENTE_IM 		"17" 
#DEFINE _NFCE_EMITENTE_CRT 		"18"
#DEFINE _NFCE_EMITENTE_CUF 		"19"  
#DEFINE _NFCE_EMTIENTE_CNUMFG 		"20" 
#DEFINE _NFCE_EMITENTE_ENDERECO_LOGR 	"21" 
#DEFINE _NFCE_EMITENTE_ENDERECO_NUMERO 	"22"
#DEFINE _NFCE_EMITENTE_ENDERECO_BAIRRO 	"23" 
#DEFINE _NFCE_EMITENTE_ENDERECO_CNUM	"24" 
#DEFINE _NFCE_EMITENTE_ENDERECO_XNUM 	"25" 
#DEFINE _NFCE_EMITENTE_ENDERECO_UF 	"26" 
#DEFINE _NFCE_EMITENTE_ENDERECO_CEP 	"27" 
#DEFINE _NFCE_CANC_INUTILIZA_AUTOMATICO	"28"

User Function LOJRNFCe(	oNFCe		, oProt		, nDecimais	, aFormas	,;
						cProtAuto	, lContigen	, cDtHoraAut, aEmitNfce	,; 
						aDestNfce	, aIdNfce	, aPagNfce	, aItemNfce	,; 
						aTotal		, cChvNFCe  , cInscMun  , aItensNFCe,;
						cXMLProt, oMyPrint ) //TBC-GO parametro add						 

	Local lPrinter 	:= .F.			
	Local cXml		:= ""
	Local cPath 			:= "\spool\"		
	Local cSession			:= GetPrinterSession()	
	Local cStartPath		:= GetSrvProfString("StartPath","")	
	Local lAdjustToLegacy	:= .T.

	Private cBmp 			:= cStartPath + "NfceLogo.bmp" 	//Logo
	Private oPrint
	
	Default oNFCe		:= NIL 
	Default oProt		:= NIL
	Default nDecimais 	:= 0
	Default aFormas 	:= {}
	Default aEmitNfce 	:= {}
	Default aDestNfce 	:= {}
	Default aIdNfce 	:= {}
	Default aPagNfce 	:= {}
	Default aItemNfce 	:= {}
	Default aTotal 		:= {}
	Default cProtAuto	:= ""
	Default lContigen	:= .T.
	Default cDtHoraAut	:= ""
	Default cChvNFCe	:= ""	
	Default cInscMun    := ""
	Default aItensNFCe  := {}    
	Default cXMLProt    := ""  		                                          	                                	    
		
	//-- TBC-GO Acrescimo para impressao Danfinha NF-e para SIGALOJA
	if oMyPrint <> Nil
		oPrint := oMyPrint
	else
		oPrint := FWMsPrinter():New("Impress�o " + iif( Type("lNFe") = "L" .and. lNFe, "NF-e_", "NFC-e_")+cChvNFCe, IMP_PDF, lAdjustToLegacy,cPath)
	endif
	
	
	If ValType(oNFCe) == "O"	
		oPrint:SetPortrait()
		oPrint:SetPaperSize(DMPAPER_A4)
		
		//-- TBC-GO Acrescimo para impressao Danfinha NF-e para SIGALOJA
		LJMsgRun("Imprimindo " + iif( Type("lNFe") = "L" .and. lNFe, "NF-e", "NFC-e"),,{|| U_LjrImpNFCE(oNFCe, oProt, nDecimais, aFormas, cProtAuto, lContigen, cDtHoraAut, ;
														aEmitNfce, aDestNfce, aIdNfce, aPagNfce, aItemNfce, aTotal, cChvNFCe, ; 
														aItensNFCe, cXMLProt )})
		
		//TBC-GO Pra quando passar o oMyPrint
		if oMyPrint <> Nil
			oPrint:Print()
		else
			oPrint:Preview()
		endif
	Else
		MsgInfo("N�o h� dados para serem impressos!")	
	EndIf
	
Return Nil

User Function LjRImpNFCE(	oNFCe		, oProt		, nDecimais	, aFormas	,; 
							cProtAuto	, lContigen	, cDtHoraAut, aEmitNfce	,; 
							aDestNfce	, aIdNfce	, aPagNfce	, aItemNfce	,;
							aTotal		, cChvNFCe	, aItensNFCe, cXMLProt )
	
	Local aItNfceAux	:= {}//Itens	
	Local nContItImp	:= 0
	Local nItemQtde		:= 0
	Local nItemUnit 	:= 0
	Local nItemTotal	:= 0
	Local nTotDesc 		:= 0
	Local nTotAcresc	:= 0 		
	Local nFtQrCode		:= 0.38 //Fator Conersao tamanho QrCode, referente a posi��o da linha 1
	Local nValFtr		:= 0 	//Valor Fatorado
	Local cTextoAux		:= ""
	Local nVlrTotal		:= 0
	Local aDtHrLocal	:= {}

	Local nX			:= 0 
	Local nY			:= 0 
	Local nAuxLn		:= 0
	
	Local nAlgL			:= 0
	Local nAlgR			:= 1
	Local nAlgC			:= 2
	
	Local cKeyQrCode	:= ""
	Local cAmbiente		:= ""
	Local cURLNFCE		:= ""	
	Local nDecVRUNIT	:= TamSX3("L2_VRUNIT")[2]	//quantidade de casas decimais a serem impressas no campo VlUnit do DANFE	
	Local nTotImpNCM	:= 0
	Local nTotVLRNCM	:= 0	
	Local nTamPgV		:= oPrint:nVertRes()//-170//Comprimento vertical da impressao
	Local oFont, oFont1, oFont2, oFont3, oFont4, oFont5
	Local cDescrPro		:= "" //Descri��o do produto
	Local nTamCol		:= 12 //Tamanho da coluna
	Local nI			:= 1 //Contador de Intera��es
	Local aColDet		:= {} //Array de Detalhes da Coluna
	Local cColuna		:= "" //Texto da Coluna
	Local cMaskTot		:= "" //Mascara de total
	Local nTamMask		:= 0 //Tamanho do Total
	Local nValDeson     := 0 //Valor do imposto da Desonera��o
	Local nTotDeson     := 0 //Valor total do imposto da desonera��o
	Local cMsgDeson     := "Valor do ICMS abatido: R$" // mensagem a ser impresso para desonera��o de ICMS
	Local aMsgNfPre     := {}   // Mensagem de Nota Fiscal Premiada
	

	//1 - Label
	//2 - Pos Coluna
	//3 - Tamanho
	//4 - Mascara
	//5 - Alinhamento
	
	aColDet := { { "Codigo", 0080, 15, "", "D"},;
				 { "Descricao", 0430, 40, "", "D"},;		
				{ "Qtd", 1250, 6, "", "E"},;	
				{ "UN", 1500, 2, "", "D"},;	
				{ "VlUnit.", 1600, 14, '@E 999,999,999.99', "E"},;				
				{ "VlTotal.", 1800, 17, '@E 999,999,999,999.99', "E"}}
				

	cMaskTot		:= aColDet[06,04]
	nTamMask		:= aColDet[06,03]
	nTamCol		:= aColDet[02, 03] //Tamanho da coluna
		
	oFont  := TFont():New("Courier New",,14,,.T. /*NEGRITO*/,,,,.T.,)	//85 caracteres por linha
	oFont1 := TFont():New("Courier New",,13,,.T. /*NEGRITO*/,,,,.T.,)	//99 caracteres por linha
	oFont2 := TFont():New("Courier New",,11,,.T. /*NEGRITO*/,,,,,)
	oFont3 := TFont():New("Courier New",,12,,.T. /*NEGRITO*/,,,,.T.,)
	oFont4 := TFont():New("Courier New",,18,,.T. /*NEGRITO*/,,,,.T.,)	//85 caracteres por linha
	oFont5 := TFont():New("Courier New",,15,,.T. /*NEGRITO*/,,,,.T.,)	
	
	//obtem o Ambiente o qual foi emitido a NFC-e
	cAmbiente := oNFCe:_NFE:_INFNFE:_IDE:_TPAMB:TEXT 
	
	// Inicia a impressao da pagina
	oPrint:StartPage()

	/*
		Divisao I
	*/
	oPrint:SetFont(oFont)
	nAuxLn := 80
	
	oPrint:SayBitmap( 0025, 0050, cBmp, 200, 200)														// Logotipo

	cTextoAux := AllTrim( "CNPJ: " + Transform(aEmitNfce:_CNPJ:TEXT, "@R 99.999.999/9999-99") ) + " "	//CNPJ
	cTextoAux += AllTrim(aEmitNfce:_XNOME:TEXT)															//Razao Social
	oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux,85) )
	nAuxLn += 40

	cTextoAux := AllTrim(aEmitNfce:_ENDEREMIT:_XLGR:TEXT) + ", " 
	cTextoAux += AllTrim(aEmitNfce:_ENDEREMIT:_NRO:TEXT) + ", "
	cTextoAux += AllTrim(aEmitNfce:_ENDEREMIT:_XBAIRRO:TEXT) + ", " 
	cTextoAux += AllTrim(aEmitNfce:_ENDEREMIT:_XMUN:TEXT) + " - "
	cTextoAux += AllTrim(aEmitNfce:_ENDEREMIT:_UF:TEXT)
	oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux,85) )
	nAuxLn += 40

	oPrint:Say( nAuxLn, aColDet[01, 02], PadC("DOCUMENTO AUXILIAR DA NOTA FISCAL DE CONSUMIDOR ELETR�NICA", 85) )
	
	/* todo aumentar a fonte*/ 
	If lContigen
		nAuxLn += 60
		oPrint:Say( nAuxLn,aColDet[01, 02], PadC("EMITIDA EM CONTING�NCIA", 66), oFont4 )
		nAuxLn += 40
		oPrint:Say( nAuxLn,aColDet[01, 02], PadC("Pendente de autoriza��o", 85), oFont )
	EndIf

	nAuxLn += 60	//quebra de linha entre as divisoes

	/*
		Divis�o II � Informa��es de Detalhe da Venda
		* a impressao dessa divis�o � opcional ou conforme definido por UF
	*/
	
	For nI := 1 to Len(aColDet)
		If aColDet[nI, 05] = "D"
			cColuna  := PadR(aColDet[nI, 01], aColDet[nI, 03])
		Else
			cColuna  := PadL(aColDet[nI, 01], aColDet[nI, 03])
		EndIf		
	
		oPrint:Say( nAuxLn,aColDet[nI, 02], cColuna, oFont1 )
	Next nI

	For nX := 1 to Len(aItemNfce)

		nContItImp++ //Contador de itens a serem impressos

		nValDeson := IIf(Len(aItensNFCe) > 0 .And. Len(aItensNFCe[nX+1]) >= 9 .And. aItensNFCe[nX+1][8] <> "S"  ,aItensNFCe[nX+1][9], 0)  
		nTotDeson += nValDeson

		nItemQtde	:= Val(aItemNfce[nX]:_PROD:_QCOM:TEXT)
		nItemUnit 	:= Val(aItemNfce[nX]:_PROD:_VUNCOM:TEXT) 
		nItemTotal	:= Val(aItemNfce[nX]:_PROD:_VPROD:TEXT) 

		nAuxLn += 40
		
		oPrint:Say( nAuxLn,aColDet[01, 02],PADR(aItemNfce[nX]:_PROD:_CPROD:TEXT,aColDet[01, 03]) + " "  ,oFont1 )	//Codigo de Produto
		
		cDescrPro := aItemNfce[nX]:_PROD:_XPROD:TEXT	
		//Se a Descricao for maior que 12 caracteres, imprimimos a descricao em uma linha soh e os outros 
		// campos na linha seguinte, caso contrario, todas as informacoes sao impressas em uma linha unica			
		oPrint:Say( nAuxLn,aColDet[02, 02],PADR(cDescrPro,nTamCol),oFont1 )					//Descricao de Produto
		oPrint:Say( nAuxLn,aColDet[03, 02],PADL(StrTran( AllTrim(Str(nItemQtde)),".", ","),aColDet[03, 03]) + space(1)	,oFont1 )	//Qtde
		oPrint:Say( nAuxLn,aColDet[04, 02],PADR(aItemNfce[nX]:_PROD:_UCOM:TEXT,aColDet[04, 03])	+ space(1)   ,oFont1 )	//Unidade de Medida
		oPrint:Say( nAuxLn,aColDet[05, 02],PadL(AllTrim(Transform(nItemUnit , aColDet[05, 04])),aColDet[05, 03]) + space(1)  	,oFont1 )	//Valor Unit.
		oPrint:Say( nAuxLn,aColDet[06, 02],PadL(AllTrim(Transform(nItemTotal, aColDet[06, 04])),aColDet[06, 03])			,oFont1 )	//Valor Total
		
		cDescrPro := Substr(cDescrPro,nTamCol+1,Len(AllTrim(cDescrPro)))
		
		Do While !Empty(cDescrPro)
			nAuxLn+=40
			If nAuxLn > nTamPgV
				nAuxLn := 20
				oPrint:EndPage()
				oPrint:StartPage()
			EndIf
			oPrint:Say( nAuxLn,aColDet[02, 02],PADR(cDescrPro, nTamCol ),oFont1 )					//Descricao de Produto
			cDescrPro := Substr(cDescrPro,nTamCol+1,Len(AllTrim(cDescrPro)))			
		EndDo

		If nValDeson > 0
			nAuxLn+=40
			oPrint:Say( nAuxLn,aColDet[02, 02],cMsgDeson, oFont1 )		//Mensagem de Desonera��o
			oPrint:Say( nAuxLn,aColDet[06, 02],PadL(AllTrim(Transform(nValDeson, aColDet[06, 04])),aColDet[06, 03])			,oFont1 )	//Valor Desonera��o
		EndIf
		
		If nAuxLn > nTamPgV
			nAuxLn := 20
			oPrint:EndPage()
			oPrint:StartPage()
		EndIf
	Next nX
	
	nAuxLn += 60	//quebra de linha entre as divisoes	
	
	/*
		Divis�o III � Informa��es de Total do DANFE NFC-e
	*/
	oPrint:SetFont(oFont1) //Times New Roman - 13 - Negrito
	
	oPrint:Say( nAuxLn,aColDet[01, 02],"Qtd. Total de Itens")	
	oPrint:Say( nAuxLn,aColDet[06, 02],PADL( AllTrim( Str(Len(aItemNfce)) ),nTamMask ) )
	
	nAuxLn += 40
	//se existir ISSQN, o VALOR TOTAL � igual a soma da tag vProd + vServ
	If LjRTemNode(aTotal,"_ISSQNTOT")
		nVlrTotal := Val(aTotal:_ICMSTOT:_VPROD:TEXT) + Val(aTotal:_ISSQNTot:_VSERV:TEXT) - nTotDeson
	Else
		nVlrTotal := Val(aTotal:_ICMSTOT:_VPROD:TEXT) - nTotDeson
	EndIf
	oPrint:Say( nAuxLn,aColDet[01, 02],"VALOR TOTAL R$")
	oPrint:Say( nAuxLn,aColDet[06, 02],PADL(AllTrim(Transform(nVlrTotal, cMaskTot)),nTamMask))

	// Verifica se possui DESCONTO ou ACRESCIMO (vOutro)
	nTotDesc	:= Val(aTotal:_ICMSTOT:_VDESC:TEXT )
	nTotAcresc	:= Val(aTotal:_ICMSTOT:_VFRETE:TEXT) + Val(aTotal:_ICMSTOT:_VSEG:TEXT) + Val(aTotal:_ICMSTOT:_VOUTRO:TEXT)

	If nTotDesc > 0
		nAuxLn += 40		
		cTextoAux := "DESCONTOS R$"
		
		oPrint:Say( nAuxLn,aColDet[01, 02], cTextoAux)		
		oPrint:Say( nAuxLn,aColDet[06, 02], PADL(AllTrim( Transform(nTotDesc, cMaskTot) ),nTamMask) )		
	EndIf
	
	If nTotAcresc > 0
		nAuxLn += 40
		cTextoAux := "ACRESCIMOS R$"
		oPrint:Say( nAuxLn,aColDet[01, 02], cTextoAux)
		oPrint:Say( nAuxLn,aColDet[06, 02], PADL(AllTrim( Transform(nTotAcresc, cMaskTot) ),nTamMask) )
	EndIf
	
	If (nTotDesc + nTotAcresc) > 0
		nAuxLn += 40
		oPrint:Say( nAuxLn,aColDet[01, 02],"Valor a Pagar R$")
		oPrint:Say( nAuxLn,aColDet[06, 02],PADL( AllTrim(Transform(Val(aTotal:_ICMSTOT:_VNF:TEXT), cMaskTot)),nTamMask))
	EndIf	
	
	oPrint:SetFont(oFont1)

	nAuxLn += 40
	oPrint:Say( nAuxLn,aColDet[01, 02],"FORMA PAGAMENTO")
	oPrint:Say( nAuxLn,aColDet[06, 02],PadL("Valor Pago R$",nTamMask) )
	
	For nX := 1 to Len(aPagNFCe)
		nAuxLn += 40
		
		If (nY := aScan(aFormas,{|x| Alltrim(x[2]) == Alltrim(aPagNfce[nX]:_TPAG:TEXT) })) > 0 			
			//TBC-GO: ajuste descricao forma pagamento
			if Alltrim(aPagNfce[nX]:_TPAG:TEXT) == '99' .AND. XmlChildEx(aPagNfce[nX],"_XPAG")!=Nil
				oPrint:Say( nAuxLn,aColDet[01, 02], aPagNfce[nX]:_XPAG:TEXT )
			else
				oPrint:Say( nAuxLn,aColDet[01, 02],aFormas[nY][1])
			endif
			oPrint:Say( nAuxLn,aColDet[06, 02], PadL( AllTrim( Transform(Val(aPagNfce[nX]:_VPAG:TEXT), cMaskTot)),nTamMask))
		Else
			//TBC-GO: ajuste descricao forma pagamento
			if XmlChildEx(aPagNfce[nX],"_XPAG")!=Nil
				oPrint:Say( nAuxLn,aColDet[01, 02], aPagNfce[nX]:_XPAG:TEXT )
			else
				oPrint:Say( nAuxLn,aColDet[01, 02],"Outros" )
			endif
			oPrint:Say( nAuxLn,aColDet[06, 02],PadL( AllTrim( Transform(Val(aPagNfce[nX]:_VPAG:TEXT), cMaskTot)),nTamMask))
		EndIf

		If nAuxLn > nTamPgV
			nAuxLn := 20
			oPrint:EndPage()
			oPrint:StartPage()
		EndIf
		
	Next nX
	
	//Troco
	If Type("oNfce:_NFE:_INFNFE:_PAG:_VTROCO") == "O"
		nAuxLn += 40
		cTextoAux := "Troco"
		oPrint:Say( nAuxLn,aColDet[01, 02], cTextoAux)
		oPrint:Say( nAuxLn,aColDet[06, 02],PADL(AllTrim(Transform( Val(oNfce:_NFE:_INFNFE:_PAG:_VTROCO:TEXT), cMaskTot)),nTamMask))
	EndIf
	
	nAuxLn += 60	//quebra de linha entre as divisoes

	/*
		DIVISAO IV � Informa��es da consulta via chave de acesso		
	*/
	oPrint:Say( nAuxLn, aColDet[01, 02], PadC("Consulte pela chave de acesso em: ", 85), oFont )
	nAuxLn += 40
	
	//Link de consulta publica
	cURLNFCE := LjNFCeURL(cAmbiente,.T.)
	oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cURLNFCE,85), oFont )	  	
	nAuxLn += 40

	//1111 2222 3333 4444 5555 6666 7777 8888 9999 0000 1111	
	cTextoAux := ""
	For nX := 1 to 44 Step 4
		cTextoAux += SubStr(cChvNFCe, nX , 4) + " "
	Next	
	oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux,85), oFont )
	
	nAuxLn += 60 	//quebra de linha entre as divisoes
	
	/*
		DIVISAO VI � Informa��es sobre o Consumidor
	*/	
	If Empty(aDestNfce)
		cTextoAux := "CONSUMIDOR N�O IDENTIFICADO"
		oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux, 85), oFont )
	Else
		If LjRTemNode(aDestNfce,"_CPF")
			cTextoAux := "CONSUMIDOR - CPF: " + Transform(aDestNfce:_CPF:TEXT, "@R 999.999.999-99")				
		ElseIf LjRTemNode(aDestNfce,"_CNPJ")				
			cTextoAux := "CONSUMIDOR - CNPJ: " + Transform(aDestNfce:_CNPJ:TEXT, "@R 99.999.999/9999-99")
		ElseIf LjRTemNode(aDestNfce,"_IDESTRANGEIRO")
			cTextoAux := "CONSUMIDOR Id. Estrangeiro: " + aDestNfce:_IDESTRANGEIRO:TEXT
		EndIf

		/*
		OPCIONALMENTE poder� ser inclu�da nesta divis�o tamb�m o nome do consumidor e/ou seu endere�o.
		No caso de emiss�o de NFC-e com entrega em domic�lio � OBRIGAT�RIA a impress�o do nome do consumidor e do endere�o de entrega.
		*/
		If LjRTemNode(aDestNfce,"_XNOME")
			cTextoAux += " " + AllTrim(aDestNfce:_XNOME:TEXT) + ' '
		EndIf		
		oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux, 85), oFont1 )
		
		//Verifica se possui endere�o
		If LjRTemNode(aDestNfce,"_ENDERDEST")
			nAuxLn += 40
			cTextoAux := aDestNfce:_ENDERDEST:_XLGR:TEXT + ', ' 
			cTextoAux += aDestNfce:_ENDERDEST:_NRO:TEXT + ', '
			cTextoAux += aDestNfce:_ENDERDEST:_XBAIRRO:TEXT + ', ' 
			cTextoAux += aDestNfce:_ENDERDEST:_XMUN:TEXT + '-'
			cTextoAux += aDestNfce:_ENDERDEST:_UF:TEXT
			
			oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux, 85), oFont1 )
		EndIf		
	EndIf	

	nAuxLn += 60	//quebra de linha entre as divisoes
	
	/*
		DIVISAO VII � Informa��es de Identifica��o da NFC-e e do Protocolo de Autoriza��o
		N�mero S�rie Emiss�o DD/MM/AAAA hh:mm:ss
	*/
	aDtHrLocal := LjUTCtoLoc(aIdNfce:_DHEMI:TEXT)
	
	//-- TBC-GO Acrescimo para impressao Danfinha NF-e para SIGALOJA
	cTextoAux := iif( Type("lNFe") = "L" .and. lNFe, "NF-e", "NFC-e") + " n�" + aIdNfce:_NNF:TEXT + " "
	cTextoAux += "S�rie " + aIdNfce:_SERIE:TEXT + " "
	cTextoAux += PadL( Day(aDtHrLocal[1]),2,"0" ) + "/" 		//DD
	cTextoAux += PadL( Month(aDtHrLocal[1]),2,"0" ) + "/"		//MM
	cTextoAux += cValToChar( Year(aDtHrLocal[1]) ) + " "		//AAAA
	cTextoAux += aDtHrLocal[2]									//hh:mm:ssa

	oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux,85), oFont )
	nAuxLn += 40
	
	If !lContigen
		aDtHrLocal := LjUTCtoLoc(cDtHoraAut)
		/* Protocolo de Autoriza��o  DD/MM/AAAA hh:mm:ss */
		cTextoAux := "Protocolo de Autoriza��o: " + cProtAuto + " "
		oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux,85), oFont )
		nAuxLn += 40

		cTextoAux := "Data de Autoriza��o: "
		cTextoAux += PadL( Day(aDtHrLocal[1]),2,"0" ) + "/"			//DD
		cTextoAux += PadL( Month(aDtHrLocal[1]),2,"0" ) + "/"		//MM
		cTextoAux += cValToChar( Year(aDtHrLocal[1]) ) + " "		//AAAA
		cTextoAux += aDtHrLocal[2]									//hh:mm:ss
		oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux,85), oFont )
	EndIf
	
	If nAuxLn > nTamPgV 
		nAuxLn := 20
		oPrint:EndPage()
		oPrint:StartPage()
	Else
		nAuxLn += 60	//quebra de linha entre as divisoes
	EndIf

	/*
		Divis�o VIII � �rea de Mensagem Fiscal
	*/	
	If Type("oNfce:_NFE:_INFNFE:_INFADIC") == "O" .AND. LjRTemNode(oNfce:_NFE:_INFNFE:_INFADIC, "_INFADFISCO")

		aInfCpl := StrToKArr(oNfce:_NFE:_INFNFE:_INFADIC:_INFADFISCO:TEXT, "|")
		nInfCpl := Len( aInfCpl )	//quantidade de quebra de linhas
		For nY := 1 to nInfCpl
			//se for a primeira linha, ja houve a quebra de linha da divisao
			If nY <> 1			
				nAuxLn += 40
			EndIf
			oPrint:Say( nAuxLn, aColDet[01, 02], aInfCpl[nY], oFont1 )
		Next
		nAuxLn += 60
	EndIf

    // Mensagem para a Nota Fiscal Premiada MS
	If !Empty(cXMLProt)
		aMsgNfPre := StrToKArr(cXMLPROT,"|")
		If Len(aMsgNfPre) > 2 .And. "DEZENAS" $ Upper(aMsgNfPre[2])
			cTextoAux := "NOTA MS PREMIADA" 
			oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux,85), oFont )
			nAuxLn += 40
			cTextoAux := aMsgNfPre[2] 
			oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux,85), oFont )
			nAuxLn += 40
			cTextoAux := SubStr(aMsgNfPre[3],1, AT("<",aMsgNfPre[3]) -1 )
			oPrint:Say( nAuxLn, aColDet[01, 02], PadC(cTextoAux,85), oFont )
			nAuxLn += 60			
		EndIf
	EndIf

	//Se Ambiente for Homologacao		
	If cAmbiente == "2"		
		oPrint:Say( nAuxLn, aColDet[01, 02], PadC("EMITIDA EM AMBIENTE DE HOMOLOGA��O � SEM VALOR FISCAL",85), oFont )
		nAuxLn += 60
	EndIf

	If lContigen
		oPrint:Say( nAuxLn, aColDet[01, 02], PadC("EMITIDA EM CONTING�NCIA",66), oFont4 )
		nAuxLn += 40
		oPrint:Say( nAuxLn, aColDet[01, 02], PadC("Pendente de autoriza��o",85), oFont )
		nAuxLn += 60
	EndIf

	/*
		DIVISAO V � Informa��es da Consulta via QR Code
		A imagem do QR Code poder� ser CENTRALIZADA (conforme o rdmake) ou
		impressa � esquerda das informa��es exigidas nas Divis�es VI e VII
	*/
	// obtem o QR-Code
	cKeyQRCode := LjNFCeQRCo(oNFCe, cAmbiente, lContigen)		
	
	/* Tratamento feito para controlar posi��o da impressao do QRCODE, pois o metodo
	do mesmo, nao esta respeitando a posi��o de impressao quando a Quebra de Pagina */
	If nAuxLn > nTamPgV-1000
		oPrint:EndPage()
		oPrint:StartPage()
		nAuxLn := 80
	EndIf  
	
	//TBC: modificado para n�o ficar muito espa�o
	nAuxLn += 400// 775
	
	//Impress�o do QrCode
	//O 4� par�metro igual � "1", define o tamanho da papel que ser� usado na impressora Laser.
	//Sendo igual � "1", est� configurado para tamnaho igual a "A4", n�o atrapalhando a visualiza��o e impress�o do Qr-Code
    oPrint:QRCode( nAuxLn, 750, cKeyQRCode, 100)

	/*		
		DIVISAO IX � Mensagem de Interesse do Contribuinte
	*/
	If Type("oNfce:_NFE:_INFNFE:_INFADIC") == "O" .AND. LjRTemNode(oNfce:_NFE:_INFNFE:_INFADIC, "_INFCPL")

		//para que haja a quebra de linha durante a impressao, separamos cada linha por |		
		aInfCpl := StrToKArr(oNfce:_NFE:_INFNFE:_INFADIC:_INFCPL:TEXT, "|")
		nInfCpl := Len( aInfCpl )	//quantidade de quebra de linhas			
		For nY := 1 to nInfCpl
			
			//TBC-GO ajustado para n�o perder informa��es quando o texto nao cabe na linha
			if len(aInfCpl[nY]) > 85
				cTextoAux := aInfCpl[nY]
				While !empty(cTextoAux)
					nAuxLn += 40
					oPrint:Say( nAuxLn, aColDet[01, 02], PadC(SubStr(cTextoAux,1,85),85), oFont1 )	
					cTextoAux := SubStr(cTextoAux, 85)
				enddo
			else
				nAuxLn += 40
				oPrint:Say( nAuxLn, aColDet[01, 02], PadC(aInfCpl[nY],85), oFont1 )
			endif

			If nAuxLn > nTamPgV
				nAuxLn := 20
				oPrint:EndPage()
				oPrint:StartPage()
			EndIf
		Next
	EndIf

	////////////////////
	//Fim da Impress�o/
	oPrint:EndPage()
	/////////////////

	LJGrvLog(Nil, "Fim da funcao LJRIMPNFCE")
Return

//--------------------------------------------------------
/*{Protheus.doc} LjRDnfNfce
Imprime Danfe(Vulgo: Danfinha)

@author  Varejo
@version P11.8
@since   27/01/2016
@return	 lRet - imprimiu 
*/
//--------------------------------------------------------
User Function LjRDnfNFCe(cXML, cXMLProt, cChvNFCe, lDANFEPad, aItensNFCe, lNFe, oMyPrint) //TBC-GO Pra quando passar o oMyPrint

Local nX			:= 0 
Local nY			:= 0 
Local aFormas		:= {}
Local aRet			:= {}
Local lRet			:= .T. //Retorna se conseguiu transmitir a Nota, n�o deve retornar erro caso ocorra problema de impressao
Local lImpComum		:= SuperGetMV("MV_LJSTPRT",,1) == 2
Local lPOS 			:= STFIsPOS()
Local cTexto		:= ""  
Local cCRLF			:= Chr(10)
Local cImpressora	:= IIF(lPOS, STFGetStation("IMPFISC"),LjGetStation("IMPFISC"))
Local cPorta		:= IIF(lPOS, STFGetStation("PORTIF"),LjGetStation("PORTIF"))
Local cModelo		:= AllTrim( cImpressora )
Local cTextoAux 	:= ""
Local cFormaPgto	:= ""
Local cVlrFormPg	:= ""
Local lContigen 	:= .T. 								//Sinaliza emissao em modo de contingencia
Local cProtAuto		:= ""								//Chave de Autorizacao
Local cAmbiente		:= ""
Local cDtHoraAut	:= ""
Local nTotDesc		:= 0 
Local nTotAcresc	:= 0								//somatoria do acrescimo da venda (frete)
Local nVlrTotal		:= 0
Local aDtHrLocal	:= {}
Local aEmitNfce		:= {}								//dados do emitente
Local aIdNfce		:= {}								//dados de Identificacao da Nfc-e
Local aPagNfce		:= {}								//dados dos pagtos  
Local aTotal		:= {}								//Totais(NF,Desconto,ICMS...)
Local nSaltoLn		:= SuperGetMV("MV_FTTEFLI",, 1)		// Linha pula entre comprovante
Local lGuil			:= SuperGetMV("MV_FTTEFGU",, .T.)	// Ativa guilhotina
Local lLj7084		:= .T.								// retorno do PE LJ7084
Local nContItImp	:= 0								//Contador de itens a serem impressos
Local aInfCpl		:= {}								//vetor com as mensagens que possuem quebra de linha
Local nInfCpl		:= 0								//quantidade de quebra de linhas
Local nMVNFCEDES	:= SuperGetMV("MV_NFCEDES",, 0)		// Exibe ou n�o desconto por item na DANFE NFC-e
Local nRetImp 		:= -1
Local cL2ItemPic	:= ""	
Local nConteudo		:= 0
Local cConteudo		:= ""
Local lCondensa		:= SuperGetMV("MV_LJCONDE",,.F.) .OR. IIf("EPSON" $ cModelo, .T., .F.)
Local cTagCondIni	:= Iif(lCondensa, TAG_CONDEN_INI , "")
Local cTagCondFim	:= IIf(lCondensa, TAG_CONDEN_FIM , "")

//variaveis de controle para impressao da coluna Descricao na DIVISAO III
Local cLinha		:= ""	//conteudo da linha que sera impressa na Divis�o III
Local nColunas		:= 48	//quantidade de caracteres de uma linha inteira
Local nIniDesc		:= 1	//indica a posi��o inicial da leitura da tag xProd (descri��o do produto)
Local nFimDesc		:= 0
Local nCodDesc		:= 0	//soma das colunas Codigo + " " + Descricao
Local lImpDesc		:= .T.	//variavel de controle que verifica se havera mais linhas para impressao da Descri��o
Local aColDiv2		:= {}	//largura das colunas da Divisao II
Local lSTImPFNfce	:= ExistFunc("STImPFNfce") .And. STImPFNfce()
Local cImgQrCode	:= ""
Local aMensagem		:= ""
Local lContinua		:= .F.
Local lSaiImp		:= .F.
Local nMVNFCEIMP	:= SuperGetMV("MV_NFCEIMP",, 1)
Local cVersao		:= ""	// Versao da NFC-e
Local lImpConting	:= .F.
Local lClasImpNfce	:= ExistFunc("LNfceTemCo")
Local oLojINfce		:= IIF( lClasImpNfce , LOJINFCE():New(), NIL ) 
Local nValDeson     := 0	// Valor do imposto da desonera��o
Local nTotDeson     := 0	// Valor Total do imposto da desonera��o
Local aMsgNfPre     := {}   // Mensagem de Nota Fiscal Premiada
Local lImpDnf		:= SuperGetMV("MV_XIMPDNF",,.F.) //Habilita pergunta de impress�o de danfinha (default .F.)
Local bGetMvFil		:= {|cParametro,lHelp,cDefault,cFil| SuperGetMV(cParametro,lHelp,cDefault,cFil)}

Default cXml 		:= ""
Default cXmlProt	:= ""
Default cChvNFCe	:= ""
Default lDanfePad	:= .F.
Default aItensNFCe  := {}
Default lNFe		:= .F.

Private oNFCe				//retorno do XML da NFCe funcao convertido para objeto
Private oProt				//retorno do XML do protocolo de autorizacao convertido para objeto
Private aDestNFCe	:= {}	//dados do destinat�rio
Private aItemNFCe	:= {}	//dados dos itens

lNFe := Substr(cChvNFCe,21,2) == "55" //-- TBC-GO Acrescimo para impressao Danfinha NF-e para SIGALOJA
If Type("aItensNFCe") <> "A"
	aItensNFCe := {}	//dados dos itens
EndIf

/*TBC: ajuste a op��o de imprimir ou n�o a nota ao finalizar a venda.*/
If lImpDnf .AND. !lNFe
	if !MsgYesNo("Deseja imprimir a danfinha?", "Aten��o")
		lSaiImp := .T.
	endif
Elseif lNFe
	nX := Aviso("NFe", "NF-e Autorizada. Como quer a impress�o da DANFE?", {"DANFE A4", "N�o Imprimir", "Cupom"}, 2)
	if nX == 2
		lSaiImp := .T.
	elseif nX == 1
		LjGrvLog( SL1->L1_NUM," Realiza a impress�o do DANFE A4",  )
		LjDANFENFe() //Chama a impressao da DANFE A4
		lSaiImp := .T.
	endif
EndIf
if lSaiImp
	cChvNFCe := Left(cChvNFCe,TamSx3("L1_KEYNFCE")[1])
	aRet := { lRet,cChvNFCe,nVlrTotal }
	LJGrvLog(Nil, "Retorno da funcao LjRDNFNFCe", aRet)
	Return  aRet
endif //FIM TBC

BEGIN SEQUENCE
	
	//-----------------------------------------------------
	// Conversao XML da NFC-e e do Protocolo de Autorizacao
	//-----------------------------------------------------
	aRet := LjXMLNFCe(cXML) //-- TBC-GO Valida��o do retorno da fun��o LjXMLNFCe
	If ValType(aRet) = "A" .and. Len(aRet) >= 1  .and. aRet[1] .and. !Empty(cXML)
		oNFCe := aRet[2]
	Else
		BREAK
	EndIf
	
	aRet := LjXMLNFCe(cXMLProt)
	If aRet[1]
		oProt := aRet[2]
	Elseif !lNFe //-- TBC-GO Acrescimo para impressao Danfinha NF-e para SIGALOJA
		BREAK
	EndIf
	
	//-- TBC-GO Tratamento para evitar erro na impress�o...
	If ValType(oNFCe) <> "O" //aborta a impressao
		MsgStop("NFC-e: N�o foi poss�vel obter o XML da NFC-e")
		BREAK
	ElseIf Type("oNfce:_NFE:_SIGNATURE:_SIGNEDINFO:_REFERENCE:_DIGESTVALUE") <> "O" //Valida��o do 'Digest Value'
		MsgStop("NFC-e: N�o foi poss�vel obter o XML da NFC-e. Erro: Digest Value")
		BREAK
	Else
		cChvNFCe := StrTran(oNFCe:_NFE:_INFNFE:_ID:TEXT, "NFe")	//Chave da NFC-e
		cVersao := oNFCe:_NFE:_INFNFE:_VERSAO:TEXT
	EndIf

	//------------------------
	// Ponto de Entrada LJ7084
	//------------------------
	// Permite definir o que ser� realizado com os dados do DANFE
	// ex: customizar a impressao, e-mail, sms ou nao imprimir
	// .T. - apos a execucao do ponto de entrada, realiza a impressao padrao do DANFE
	// .F. - apos a execucao do ponto de entrada, NAO realiza a impressao padrao do DANFE
	If ExistBlock("LJ7084")
		LjGrvLog( NIL, "Antes da execu��o do PE LJ7084")
		lLj7084 := ExecBlock( "LJ7084", .F., .F., {oNFCe, oProt} )
		LjGrvLog( NIL, "Antes da execu��o do PE LJ7084", lLj7084)
		If ValType(lLj7084) <> "L"
			lLj7084 = .T.
		EndIf
	EndIf

	//--------------------------
	// Impressao padrao do DANFE
	//--------------------------
	If (lDanfePad .AND. lLj7084) .Or. lSTImPFNfce
		
		//TBC-GO Pra quando passar o oMyPrint
		lImpComum := (lImpComum .And. !lSTImPFNfce) .OR. oMyPrint<>Nil
		
		//----------------------------------------
		// Comunicacao com a impressora nao fiscal
		//----------------------------------------
		If !lImpComum .AND. !lPos .AND. nHdlECF == -1		
			cImpressora	:= LJGetStation("IMPFISC")
			cPorta := "AUTO"
			If lSTImPFNfce 
				STImPFNfce( @{"C",cImpressora,nHdlECF})
			Else			
				If !IsBlind()
					LjMsgRun( "Aguarde. Abrindo a Impressora N�o Fiscal...",, { || nHdlECF := INFAbrir( cImpressora,cPorta ) } )
				Else
					conout("Aguarde. Abrindo a Impressora...")
					nHdlECF := INFAbrir( cImpressora,cPorta )
				EndIf
			EndIf
			
			//Verifica se houve comunicacao com a impressora
			If nHdlECF == -1
				If !IsBlind()
					If ExistFunc("LjObgCpVen") .And.	ExistFunc("INFCon")	//LOJNFCE.PRW e LOJXECF.PRX
						// Se obrigar a impressao, verifica se a impressora est� conectada
						lObrigaImp := LjObgCpVen(@aMensagem)

						If lObrigaImp
							
							lContinua := INFCon(.T.)	// Testa comunicacao com ECNF

							If !lContinua .And. Len(aMensagem) > 0
								Aviso( aMensagem[1], aMensagem[2], {aMensagem[3]} )
							EndIf
						EndIf
					EndIf
				Else
					conout("NFC-e: N�o foi poss�vel estabelecer comunica��o com a Impressora:" + cImpressora)
					//nao ha necessidade de retornar erro quando houver erro de impressora
				EndIf				
				
				If !lContinua
					//aborta a impressao
					BREAK
				EndIf
			EndIf
		EndIf
		
		//Valida se existe nDecimais, variavel � Privete declarada no Loja701
		If Type("nDecimais") == "U"
			nDecimais := MsDecimais(1)				// Quantidade de casas decimais
		EndIf

		//TBC-GO formas do posto
		aFormas := MyLjDfRetFrm() //LjDfRetFrm()

		lContigen := oNFCe:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT <> "1"
		If lClasImpNfce
			oLojINfce:lConting := lContigen
		EndIf

		//Verifica se conseguiu montar o objeto do XML e sinaliza nao contingencia 
		If (oProt <> NIL) .And. LjRTemNode(oProt:_PROTNFE:_INFPROT,"_NPROT")

			cProtAuto := AllTrim(oProt:_PROTNFE:_INFPROT:_NPROT:TEXT)

			If LjRTemNode(oProt:_PROTNFE:_INFPROT,"_DHRECBTO")
				cDtHoraAut := oProt:_PROTNFE:_INFPROT:_DHRECBTO:TEXT
			EndIf
		EndIf

		//------------------------------------------------------------
		//Separa objetos do XML para facilitar a manipulacao dos dados
		//------------------------------------------------------------
		aEmitNfce := oNfce:_NFE:_INFNFE:_EMIT 		//Emitente

		//Ambiente (Normal ou Homologa��o)
		cAmbiente := oNFCe:_NFE:_INFNFE:_IDE:_TPAMB:TEXT

		//Quando n�o informa CPF/CNPJ, n�o retorna o objeto _DEST		
		If LjRTemNode(oNfce:_NFE:_INFNFE,"_DEST")
			aDestNfce := oNfce:_NFE:_INFNFE:_DEST 	//Destinat�rio
		EndIf

		aIdNfce	:= oNfce:_NFE:_INFNFE:_IDE			//Detalhe da NFC-e
		
		//Quando possui apenas um item, n�o retorna um Array de _PAG e sim os detalhes da Forma de Pagto, caso contrario retorna Array
		If cVersao == "4.00"
			If Type("oNfce:_NFE:_INFNFE:_PAG:_DETPAG[1]") == "O"
				aPagNfce := oNfce:_NFE:_INFNFE:_PAG:_DETPAG
			Else
				aAdd(aPagNfce, oNfce:_NFE:_INFNFE:_PAG:_DETPAG)
			EndIf
		Else
			If Type("oNfce:_NFE:_INFNFE:_PAG[1]") == "O"
				aPagNfce := oNfce:_NFE:_INFNFE:_PAG
			Else
				aAdd(aPagNfce, oNfce:_NFE:_INFNFE:_PAG)
			EndIf
		EndIf
				
		//Quando possui apenas um item, n�o retorna um Array de _DET e sim os detalhes do produto, caso contrario retorna Array	
		If Type("oNfce:_NFE:_INFNFE:_DET[1]") == "O"
			aItemNfce := oNfce:_NFE:_INFNFE:_DET
		Else
			aAdd( aItemNfce, oNfce:_NFE:_INFNFE:_DET )
		EndIf
		
		//Total da NF
		aTotal := oNfce:_NFE:_INFNFE:_TOTAL
		
		/*Verifica compatibilidade de Impressao: 4-DANFE Detalhada e 5-DANFE Resumida
			0=Sem gera��o de DANFE; 
			1=DANFE normal, Retrato; 
			2=DANFE normal, Paisagem; 
			3=DANFE Simplificado; 
			4=DANFE NFC-e; 
			5=DANFE NFC-e em mensagem eletr�nica (o envio de mensagem eletr�nica pode ser feita de forma simult�nea com a impress�o do DANFE; usar o tpImp=5 quando esta for a �nica forma de disponibiliza��o do DANFE).
				
			O parametro MV_NFTPIMP controla o preenchimento da TAG
		*/
		//-- TBC-GO acrescimo tipo 1 e 3 para emissao de danfinha de NFe na impressora nao fiscal
		If !aIdNfce:_TPIMP:TEXT $ "1345"
			If !IsBlind()
				MsgStop("Nfc-e: Tipo de Impress�o incompat�vel: "+aIdNfce:_TPIMP:TEXT)
			Else
				Conout("Nfc-e: Tipo de Impress�o incompat�vel: "+aIdNfce:_TPIMP:TEXT)
			EndIf			
			//aborta a rotina de impressao
			BREAK
		EndIf
		
		//TBC-GO ajuste para caso for imprimir em impressora comum nao precisar monta o cTexto
		If !lImpComum
			If !lSTImPFNfce
				/*
					DIVISAO I - Informa��es do Cabe�alho
				*/
				/* Logotipo da empresa - (utilizar a ferramenta da pr�pria fabricante) */
				cTexto += TAG_BMP_INI + TAG_BMP_FIM
		
				/* CNPJ: 99.999.999/9999-99 Raz�o social do Emitente */		
				cTextoAux := "CNPJ: " + Transform(aEmitNfce:_CNPJ:TEXT, "@R 99.999.999/9999-99") + " "
				cTextoAux += TAG_NEGRITO_INI + AllTrim(aEmitNfce:_XNOME:TEXT) + TAG_NEGRITO_FIM
				
				cTexto += TAG_CENTER_INI
				cTexto += cTagCondIni
				cTexto += cTextoAux
				cTexto += cTagCondFim
				cTexto += cCRLF

				/* Endere�o Completo, nro, bairro, Munic�pio - UF */
				cTextoAux := AllTrim(aEmitNfce:_ENDEREMIT:_XLGR:TEXT) 	+ ","
				cTextoAux += AllTrim(aEmitNfce:_ENDEREMIT:_NRO:TEXT)	+ ","
				cTextoAux += AllTrim(aEmitNfce:_ENDEREMIT:_XBAIRRO:TEXT)+ ","
				cTextoAux += AllTrim(aEmitNfce:_ENDEREMIT:_XMUN:TEXT)	+ ","
				cTextoAux += AllTrim(aEmitNfce:_ENDEREMIT:_UF:TEXT)
		
				cTexto += (cTagCondIni + cTextoAux + cTagCondFim) 
				cTexto += cCRLF
			EndIf
			
			cTextoAux := (cTagCondIni + "DOCUMENTO AUXILIAR DA")
			cTextoAux += cCRLF

			If lNfe
				cTextoAux += (PadC("NOTA FISCAL ELETR�NICA",SLG->LG_LARGCOL) + cTagCondFim) 
			Else
				cTextoAux += (PadC("NOTA FISCAL DE CONSUMIDOR ELETR�NICA",SLG->LG_LARGCOL) + cTagCondFim)
			Endif

			cTexto += cTextoAux
			cTexto += TAG_CENTER_FIM
			cTexto += Replicate(cCRLF,2)

			If lContigen
				cTexto += TAG_CENTER_INI
				cTexto += (TAG_NEGRITO_INI + "EMITIDA EM CONTING�NCIA" + TAG_NEGRITO_FIM)
				cTexto += cCRLF
				cTexto += (cTagCondIni + "Pendente de autoriza��o" + cTagCondFim)
				cTexto += TAG_CENTER_FIM
				cTexto += Replicate(cCRLF,2)
			EndIf

			/*
				DIVISAO II � Informa��es de detalhes de produtos/servi�os
				A impressao dessa divis�o � opcional ou conforme definido por UF
			*/
			//
			// Cabecalho da Divisao II e aColDiv2
			// A soma de todas as colunas do cabecalho deve ser igual a variavel nColunas (padrao 48)
			// O array aColDiv2 possui a quantidade de caracteres de cada coluna, entao se alterar qualquer posicao do cabecalho
			// deve-se alterar a sua respectiva posicao. Os espacoes entre as colunas nao sao considerados, portanto a soma
			// das posicoes do array e a dos espacos (5) devem ser igual a variavel nColunas.		 
			//
			cTexto += (TAG_NEGRITO_INI + TAG_CENTER_INI + cTagCondIni)
			cTexto += "Codigo          Desc. Qtd UN Vlr Unit. Vlr Total"	//48 colunas
			cTexto +=  (cTagCondFim + TAG_CENTER_FIM + TAG_NEGRITO_FIM)
			cTexto += cCRLF
			
			// ATENCAO: se alterar algum valor do array, deve-se alterar o cabecalho acima tambem
			Aadd(aColDiv2, 15)	// Codigo
			Aadd(aColDiv2, 04)	// Descricao
			Aadd(aColDiv2, 05)	// Qtd
			Aadd(aColDiv2, 02)	// Un
			Aadd(aColDiv2, 08)	// VlUnit.
			Aadd(aColDiv2, 09)	// VlTotal
			
			// soma das colunas Codigo + " " + Descricao 
			nCodDesc := aColDiv2[1] + 1 + aColDiv2[2]
		
			//obtemos a Picture que sera utilizada para o valor unitario
			//-- TBC-GO ajustado para pegar a picture do campo L2_VRUNIT
			cL2ItemPic := PesqPict("SL2","L2_VRUNIT") //"@E " + Right( "@E 999,999,999.99", aColDiv2[5] )
			//-- TBC-GO ajustado para pegar a picture do campo L2_QUANT
			cL2QutdPic := PesqPict("SL2","L2_QUANT")
			
			For nX := 1 to Len(aItemNfce)

				nContItImp++

				// Codigo			
				cLinha := PadR( aItemNfce[nX]:_PROD:_CPROD:TEXT, aColDiv2[1] ) + " "

				// Descricao				
				cConteudo := aItemNfce[nX]:_PROD:_XPROD:TEXT
				nTamDesc := Len( cConteudo )

				//
				// variaveis de controle da impressao da Descricao
				//
				lImpDesc := .T.
				nIniDesc := 1
				nFimDesc := aColDiv2[2] + aColDiv2[3] + aColDiv2[4] + aColDiv2[5] + aColDiv2[6] + 4 //4 espa�os separadores

				nValDeson := IIf(Len(aItensNFCe) > 0 .And. Len(aItensNFCe[nX+1 ]) >= 9 .And. aItensNFCe[nX+1][8] <> "S"  ,aItensNFCe[nX+1][9], 0) 

				While lImpDesc
			
					//agora a linha contem o Codigo e Descricao do produto
					cLinha += SubStr(cConteudo, nIniDesc, nFimDesc)
		
					//
					//	Se o tamanho do Codigo + Descricao do produto ultrapassar a coluna Descricao, 
					//	entao a impressao das informacoes do item continuara na proxima linha a partir da coluna Codigo
					//
					If Len(cLinha) > nCodDesc

						//texto a ser impresso
						cLinha := PadR(cLinha, nColunas)
						cTexto += (TAG_CENTER_INI + cTagCondIni + cLinha + cTagCondFim + TAG_CENTER_FIM)					
						cTexto += cCRLF

						//
						// Controle para a PROXIMA linha
						//
						cLinha := ""
					
						//subtraimos do tamanho da Descricao, o conteudo ja impresso
						nTamDesc -= nFimDesc
					
						//somamos a posicao inicial a ser lido da Descricao, o conteudo ja impresso
						nIniDesc += nFimDesc
		
						If nTamDesc < 1
							//toda a descricao foi impressa, entao podemos continuar a imprimir as outras informacoes
							nFimDesc := 0
						ElseIf nTamDesc > nCodDesc
							//a descricao restante ultrapassa a coluna Descricao, entao ela usara a linha toda
							nFimDesc := nColunas
						Else
							//a descricao restante somente utilizara as colunas Codigo e Descricao
							nFimDesc := nCodDesc
						EndIf
				
					Else
						//nao sera necessario adicionar uma linha para impressao das outras informacoes dos itens
						lImpDesc := .F.
						cLinha := PadR( cLinha, nCodDesc ) + " "
					EndIf

				EndDo
			
				// Qtd - quantidade
				nConteudo := Val( aItemNfce[nX]:_PROD:_QCOM:TEXT )
				//-- TBC-GO ajustado para pegar a picture do campo L2_QUANT
				//cConteudo := cValToChar(nConteudo)
				cConteudo := AllTrim(Transform(nConteudo, cL2QutdPic)) + " "
				//cLinha += PadL(cConteudo, aColDiv2[3]) + " "
				cLinha += cConteudo

				// Un - unidade de medida
				cLinha += PadL(aItemNfce[nX]:_PROD:_UCOM:TEXT, aColDiv2[4]) + " "

				// VlUnit. - valor unitario
				nConteudo := Val( aItemNfce[nX]:_PROD:_VUNCOM:TEXT ) 
				cConteudo := Transform(nConteudo, cL2ItemPic) + " "
				cLinha += cConteudo

				// VlTotal - valor total
				nConteudo := Val( aItemNfce[nX]:_PROD:_VPROD:TEXT )
				cConteudo := Transform(nConteudo, '@E 999,999.99')
				cLinha += cConteudo
			
				cTexto += (TAG_CENTER_INI + cTagCondIni + cLinha + cTagCondFim + TAG_CENTER_FIM)
				cTexto += cCRLF

				If  nValDeson > 0 				    
					cLinha := "Valor do ICMS abatido: R$  "+ Padl(Transform(nValDeson,'@E 999,999.99'),nColunas - 26 )
					cTexto += (TAG_CENTER_INI + cTagCondIni + cLinha + cTagCondFim + TAG_CENTER_FIM)
					cTexto += cCRLF
					nTotDeson += nValDeson
				EndIf

				If nMVNFCEDES == 1
					If Type("aItemNfce["+AllTrim(Str(nX))+"]:_PROD:_VDESC") == "O"
						nConteudo := Val(aItemNfce[nX]:_PROD:_VDESC:TEXT )
						cConteudo := Transform(nConteudo, '@E 99,999.99')	//retorna 9 caracteres

						//a string com o desconto deve ser igual a variavel nColunas (texto + valor = nColunas)
						cLinha := "Desconto no Item                     - " + cConteudo

						cTexto += (TAG_CENTER_INI + cTagCondIni + cLinha + cTagCondFim + TAG_CENTER_FIM)
						cTexto += cCRLF
					EndIf
				EndIf
				
				//Tratamento necess�rio pois dependendo tamanho das informa��es dos itens a serem impressos,
				//apos um determinado tamanho o texto n�o � impresso, gerando o erro de DEBUG/TOTVSAPI na DLL.
				//para isso foi quebrada a impress�o em 50 itens.			
				If nContItImp == 30
					If !lSTImPFNfce
						If !lPos
							//Tratamento paliativo para impressora Bematech, ate a solucao de problema de comunicacao ppor parte da BEMATECH
							nRetImp := 999						
							lSaiImp := .F.
							While nRetImp <> 0 .And. !lSaiImp .And. LjAskImp(nRetImp)
								LJGrvLog(Nil, "Envia o texto para a impressao intermediaria (INFTexto)")
								
								lImpConting := .F.
								If lClasImpNfce
									//Se retorno for falso, n�o houve impress�o em contingencia
									lImpConting := oLojINfce:ImpMsgCon(lContigen, @cTexto, @nRetImp)
								EndIf
								
								If !lImpConting
									nRetImp := INFTexto(cTexto)  //Envia comando para a Impressora
								EndIf
							
								If nMVNFCEIMP == 1 .And. nRetImp <> 0 .And. !MsgYesNo("Houve erro na impress�o, deseja tentar imprimir novamente ?", "Aten��o")
									lSaiImp := .T.
									LjGrvLog( Nil,	" Impress�o da NFC-e est� como n�o obrigat�rio [MV_NFCEIMP igual a 1], " +; 
													" houve erro na impress�o do comprovante e usu�rio optou por sair sem imprimir  ")
								EndIf
							End
						Else
							lImpConting := .F.
							If lClasImpNfce
								//Se retorno for falso, n�o houve impress�o em contingencia
								lImpConting := oLojINfce:ImpMsgCon(lContigen, @cTexto, @nRetImp)
							EndIf
								
							If !lImpConting
								LJGrvLog(Nil, "Envia o texto para a impressao intermediaria (STWPrintTextNotFiscal)")
								nRetImp := STWPrintTextNotFiscal(cTexto)
								LJGrvLog(Nil, "Retorno do texto para a impressao intermediaria (STWPrintTextNotFiscal)",nRetImp)
							EndIf
						EndIf
						cTexto	:= ""
					EndIf
					nContItImp	:= 0
				EndIf
			Next

			/*
				DIVISAO III � Informa��es de Total do DANFE NFC-e
			*/
			//--------------------------------------------
			// "Qtd. Total de Itens"
			//--------------------------------------------		
			cTextoAux 	:= "QTD. TOTAL DE ITENS"
			cTextoAux 	:= cTextoAux + PadL( cValToChar(Len(aItemNfce)), nColunas - Len(cTextoAux) )

			cTexto 		+= (TAG_CENTER_INI + cTagCondIni + cTextoAux + cTagCondFim + TAG_CENTER_FIM)
			cTexto		+= cCRLF
			
			//--------------------------------------------
			// "Valor Total R$"
			//--------------------------------------------
			//se existir ISSQN, o VALOR TOTAL � igual a soma da tag vProd + vServ
			If LjRTemNode(aTotal,"_ISSQNTOT")
				nVlrTotal := Val(aTotal:_ICMSTOT:_VPROD:TEXT) + Val(aTotal:_ISSQNTot:_VSERV:TEXT)  - nTotDeson
			Else
				nVlrTotal := Val(aTotal:_ICMSTOT:_VPROD:TEXT) - nTotDeson
			EndIf		

			cTextoAux 	:= "VALOR TOTAL R$"		
			cTextoAux 	:= cTextoAux + PadL( AllTrim(Transform(nVlrTotal, '@E 999,999,999,999.99')), nColunas-Len(cTextoAux) )
			
			cTexto			+= (TAG_CENTER_INI + cTagCondIni + cTextoAux + cTagCondFim + TAG_CENTER_FIM)
			cTexto			+= cCRLF
			
			// Verifica se possui DESCONTO ou ACRESCIMO (vOutro)
			nTotDesc	:= Val(aTotal:_ICMSTOT:_VDESC:TEXT )
			nTotAcresc	:= Val(aTotal:_ICMSTOT:_VFRETE:TEXT) + Val(aTotal:_ICMSTOT:_VSEG:TEXT) + Val(aTotal:_ICMSTOT:_VOUTRO:TEXT)
			
			If nTotDesc > 0
				cTextoAux := "DESCONTOS R$"
				cTextoAux := cTextoAux + PadL( AllTrim(Transform( nTotDesc, '@E 999,999,999,999,999.99')), nColunas-Len(cTextoAux) )
				cTexto	+= (TAG_CENTER_INI + cTagCondIni + cTextoAux + cTagCondFim + TAG_CENTER_FIM)
				cTexto	+= cCRLF
			EndIf

			If nTotAcresc > 0
				cTextoAux := "ACRESCIMOS R$"
				cTextoAux := cTextoAux + PadL( AllTrim(Transform( nTotAcresc, '@E 999,999,999,999,999.99')), nColunas-Len(cTextoAux) )
				cTexto	+= (TAG_CENTER_INI + cTagCondIni + cTextoAux + cTagCondFim + TAG_CENTER_FIM)
				cTexto	+= cCRLF
			EndIf
			
			If (nTotDesc + nTotAcresc) > 0
				//--------------------------------------------
				// "VALOR A PAGAR R$"
				//--------------------------------------------		
				cTextoAux 	:= "VALOR A PAGAR R$"
				cTextoAux 	:= cTextoAux + PadL( AllTrim(Transform(Val(aTotal:_ICMSTOT:_VNF:TEXT), '@E 999,999,999,999,999.99')), nColunas-Len(cTextoAux) )
				cTextoAux	:= TAG_CENTER_INI + cTextoAux + TAG_CENTER_FIM

				cTexto		+= (TAG_NEGRITO_INI + cTagCondIni + cTextoAux + cTagCondFim + TAG_NEGRITO_FIM)
				cTexto		+= cCRLF
			EndIf
							
			//-----------------------------------------------------------
			// "FORMA PAGAMENTO                         VALOR A PAGAR R$"
			//-----------------------------------------------------------
			cTextoAux := "FORMA PAGAMENTO" + "VALOR A PAGAR R$"
			cTexto += (TAG_CENTER_INI + cTagCondIni)		
			cTexto += ("FORMA PAGAMENTO" + Space( nColunas-Len(cTextoAux) ) + "VALOR A PAGAR R$")
			cTexto += (cTagCondFim + TAG_CENTER_FIM)

			//For nX := 1 to Len(aPagNFCe)
			//	cTexto += cCRLF
			//
			//	nY := aScan( aFormas, {|x| Alltrim(x[2]) == Alltrim(aPagNfce[nX]:_TPAG:TEXT)} )
			//	If nY > 0
			//		cFormaPgto := aFormas[nY][1]
			//	Else
			//		cFormaPgto := "OUTROS"
			//	EndIf
			//	cVlrFormPg := AllTrim( Transform(Val(aPagNfce[nX]:_VPAG:TEXT), '@E 999,999,999,999,999.99') )
			//
			//	cTexto += (TAG_CENTER_INI + cTagCondIni + cFormaPgto + PadL( cVlrFormPg, nColunas-Len(cFormaPgto) ) + cTagCondFim + TAG_CENTER_FIM)
			//Next nX

			//-- TBC-GO - IMPRIME AS FORMAS DE PAGAMENTO CONFORME O ORCAMENTO (SL4)
			//-- Ajustado para pegar os pagamentos da SL4 
			SL4->(DbSetOrder(1)) //L4_FILIAL+L4_NUM+L4_ORIGEM
			SL4->(DbSeek(xFilial("SL4")+SL1->L1_NUM))
			While SL4->(!Eof()) .and. SL4->(L4_FILIAL+L4_NUM) == (xFilial("SL4")+SL1->L1_NUM)
			
				cTexto += cCRLF

				nY := aScan( aFormas, {|x| Alltrim(x[3]) == Alltrim(SL4->L4_FORMA)} )
				If nY > 0
					If Alltrim(SL4->L4_FORMA) $ 'CC/CD' .AND. SubStr(SL4->L4_ADMINIS,1,3) $ Eval(bGetMvFil,"MV_XADMFID",,"")
						cFormaPgto := "OUTROS"
					Else
						cFormaPgto := aFormas[nY][1]
					EndIf
				Else
					cFormaPgto := "OUTROS"
				EndIf
				
				cVlrFormPg := AllTrim( Transform(SL4->L4_VALOR, '@E 999,999,999,999,999.99') )

				cTexto += (TAG_CENTER_INI + cTagCondIni + cFormaPgto + PadL( cVlrFormPg, nColunas-Len(cFormaPgto) ) + cTagCondFim + TAG_CENTER_FIM)
				
				SL4->(DbSkip())
			EndDo
			
			//-- TBC-GO - IMPRIME O TEXTO PAGAMENTO COM CREDITO
			If SL1->L1_CREDITO > 0
				cTexto += cCRLF
				
				nY := aScan( aFormas, {|x| Alltrim(x[3]) == "CR"} )
				If nY > 0
					cFormaPgto := aFormas[nY][1]
				Else
					cFormaPgto := "OUTROS"
				EndIf

				cVlrFormPg := AllTrim( Transform(SL1->L1_CREDITO, '@E 999,999,999,999,999.99') )
				cTexto += (TAG_CENTER_INI + cTagCondIni + cFormaPgto + PadL( cVlrFormPg, nColunas-Len(cFormaPgto) ) + cTagCondFim + TAG_CENTER_FIM)
			EndIf
			
			// Troco
			If Type("oNfce:_NFE:_INFNFE:_PAG:_VTROCO") == "O"
				cTextoAux := "Troco"
				cTextoAux := cTextoAux + PadL( AllTrim(Transform( Val(oNfce:_NFE:_INFNFE:_PAG:_VTROCO:TEXT), '@E 999,999,999,999,999.99')), nColunas-Len(cTextoAux) )
				cTexto += cCRLF
				cTexto += (TAG_CENTER_INI + cTagCondIni + cTextoAux + cTagCondFim + TAG_CENTER_FIM)
			EndIf
			cTexto += Replicate(cCRLF,2)

			////-- TBC-GO - IMPRIME O TEXTO TROCO
			////-- Apensa nao estar no XML a impressao do mesmo e apenas devido a ser 
			////-- varejo (habito usuario)
			//If GetNewPar("MV_LJTROCO",.T.) .and. SL1->L1_TROCO1 > 0
			//	cTexto 		+= cCRLF
			//	cVlrFormPg  := AllTrim( Transform( SL1->L1_TROCO1, '@E 999,999,999,999,999.99') )
			//	cTexto 		+= TAG_CENTER_INI + cTagCondIni + "TROCO:"
			//	cTexto 		+= PadL( cVlrFormPg, nColunas-6 )
			//	cTexto		+= cTagCondFim + TAG_CENTER_FIM
			//EndIf
			//cTexto += Replicate(cCRLF,2)

			/*
				DIVISAO IV � Informa��es da consulta via chave de acesso
			*/
			cTexto += TAG_CENTER_INI
			cTexto += (cTagCondIni + TAG_NEGRITO_INI + "Consulte pela Chave de Acesso em" + TAG_NEGRITO_FIM + cTagCondFim)
			cTexto += cCRLF

			cTexto += TAG_CONDEN_INI
			//URL de Consulta Publica
			cTexto += LjNFCeURL(cAmbiente, .T., lNFe)
			cTexto += cCRLF

			//1111 2222 3333 4444 5555 6666 7777 8888 9999 0000 1111
			For nX := 1 to 44 Step 4
				cTexto += SubStr(cChvNFCe, nX , 4) + " "
			Next
			cTexto += TAG_CONDEN_FIM
			cTexto += TAG_CENTER_FIM
			cTexto += Replicate(cCRLF,2)

			/*
				Divis�o VI � Informa��es sobre o Consumidor
			*/		
			cTexto += TAG_CENTER_INI		

			If Empty(aDestNfce)
				cTexto += (cTagCondIni + TAG_NEGRITO_INI + "CONSUMIDOR N�O IDENTIFICADO" + TAG_NEGRITO_FIM + cTagCondFim)			 
			Else
				cTexto += (cTagCondIni + TAG_NEGRITO_INI + "CONSUMIDOR -" + TAG_NEGRITO_FIM + cTagCondFim)

				cTexto += cTagCondIni + TAG_NEGRITO_INI
				If LjRTemNode(aDestNfce,"_CPF")
					cTexto += " CPF: " 
					cTexto += Transform(aDestNfce:_CPF:TEXT, "@R 999.999.999-99")
				ElseIf LjRTemNode(aDestNfce,"_CNPJ")
					cTexto += " CNPJ: " 
					cTexto += Transform(aDestNfce:_CNPJ:TEXT, "@R 99.999.999/9999-99")
				ElseIf LjRTemNode(aDestNfce,"_IDESTRANGEIRO")
					cTexto += " Id. Estrangeiro: "
					cTexto += aDestNfce:_IDESTRANGEIRO:TEXT
				EndIf
				cTexto += TAG_NEGRITO_FIM

				If LjRTemNode(aDestNfce,"_XNOME")
					cTexto += " " + AllTrim(aDestNfce:_XNOME:TEXT) + " "
				EndIf

				//
				//OPCIONALMENTE poder� ser inclu�da nesta divis�o tamb�m o nome do consumidor e/ou seu endere�o.
				//No caso de emiss�o de NFC-e com entrega em domic�lio � OBRIGAT�RIA a impress�o do nome do consumidor e do endere�o de entrega.
				//			
				If LjRTemNode(aDestNfce,"_ENDERDEST")
					cTexto += cCRLF
					cTexto += aDestNfce:_ENDERDEST:_XLGR:TEXT + ',' 
					cTexto += aDestNfce:_ENDERDEST:_NRO:TEXT + ','
					cTexto += aDestNfce:_ENDERDEST:_XBAIRRO:TEXT + ',' 
					cTexto += aDestNfce:_ENDERDEST:_XMUN:TEXT + '-'
					cTexto += aDestNfce:_ENDERDEST:_UF:TEXT				
				EndIf
				cTexto += cTagCondFim				
			EndIf
			cTexto += TAG_CENTER_FIM
			cTexto += Replicate(cCRLF,2)

			/*
				DIVISAO VI � Informa��es de Identifica��o da NFC-e e do Protocolo de Autoriza��o
				N�mero S�rie Emiss�o DD/MM/AAAA hh:mm:ss
			*/		
			aDtHrLocal := LjUTCtoLoc(aIdNfce:_DHEMI:TEXT)

			cTextoAux := iif( lNFe, "NF-e","NFC-e") + " n " + aIdNfce:_NNF:TEXT + " " 		//N�mero da NFC-e
			cTextoAux += "S�rie " + aIdNfce:_SERIE:TEXT + " " 		//S�rie da NFC-e
			cTextoAux += PadL( Day(aDtHrLocal[1]),2,"0" ) + "/"		//DD
			cTextoAux += PadL( Month(aDtHrLocal[1]),2,"0" ) + "/"	//MM
			cTextoAux += cValToChar( Year(aDtHrLocal[1]) ) + " "	//AAAA
			cTextoAux += aDtHrLocal[2]								//hh:mm:ssa
			
			cTexto += (TAG_CENTER_INI + TAG_NEGRITO_INI + cTagCondIni)
			cTexto += cTextoAux
			cTexto += (cTagCondFim + TAG_NEGRITO_FIM + TAG_CENTER_FIM)
			cTexto += cCRLF
			
			If lClasImpNfce
				oLojINfce:RetMsgCon(lContigen)
				
				If !Empty(AllTrim(oLojINfce:cMsgConting))
					cTexto += oLojINfce:cMsgConting
				EndIf
			EndIf

			// obtemos o Protocolo de Autorizacao do XML retornado do SEFAZ (se modalidade NORMAL)
			If !lContigen
				aDtHrLocal := LjUTCtoLoc(cDtHoraAut)
				
				//Data de Autoriza��o: DD/MM/AAAA hh:mm:ss
				cTextoAux := (cTagCondIni + TAG_NEGRITO_INI + "Data de Autoriza��o: " + TAG_NEGRITO_FIM + cTagCondFim)
				cTextoAux += cTagCondIni
				cTextoAux += PadL( Day(aDtHrLocal[1]),2,"0" ) + "/"		//DD
				cTextoAux += PadL( Month(aDtHrLocal[1]),2,"0" ) + "/"	//MM
				cTextoAux += cValToChar( Year(aDtHrLocal[1]) ) + " "	//AAAA
				cTextoAux += aDtHrLocal[2]								//hh:mm:ss
				cTextoAux += cTagCondFim

				cTexto += TAG_CENTER_INI
				cTexto += (cTagCondIni + TAG_NEGRITO_INI + "Protocolo de Autoriza��o: " + TAG_NEGRITO_FIM + cTagCondFim)
				cTexto += (cTagCondIni + cProtAuto + cTagCondFim)
				cTexto += cCRLF
				cTexto += cTextoAux 
				cTexto += TAG_CENTER_FIM
				cTexto += cCRLF			
			EndIf		

			/*
				DIVISAO VIII � �rea de Mensagem Fiscal
			*/		
			If Type("oNfce:_NFE:_INFNFE:_INFADIC") == "O" .AND. LjRTemNode(oNfce:_NFE:_INFNFE:_INFADIC, "_INFADFISCO")
				
				//para que haja a quebra de linha durante a impressao, separamos cada linha por |
				aInfCpl := StrToKArr(oNfce:_NFE:_INFNFE:_INFADIC:_INFADFISCO:TEXT, "|")
				nInfCpl := Len( aInfCpl )	//quantidade de quebra de linhas			

				cTextoAux := ""

				For nY := 1 to nInfCpl
					
					If nY == 1 .And. lSTImPFNfce
						STImPFNfce(@{"M",cTextoAux})
					EndIf
					
					cTextoAux += aInfCpl[nY]
					If nY <> nInfCpl
						cTextoAux += cCRLF
					EndIf
				Next
			
				cTexto += TAG_CENTER_INI + cTagCondIni
				cTexto += cTextoAux
				cTexto += cTagCondFim + TAG_CENTER_FIM
				cTexto += cCRLF
			EndIf

			// Mensagem para a Nota Fiscal Premiada MS
			If !Empty(cXMLProt)
				aMsgNfPre := StrToKArr(cXMLPROT,"|")
				If Len(aMsgNfPre) > 2 .And. "DEZENAS" $ Upper(aMsgNfPre[2])
					cTexto += TAG_CENTER_INI + cTagCondIni
					cTexto += "NOTA MS PREMIADA" + cCRLF
					cTexto += aMsgNfPre[2] + cCRLF
					CtEXTO += SubStr(aMsgNfPre[3],1, AT("<",aMsgNfPre[3]) -1 )
					cTexto += cTagCondFim + TAG_CENTER_FIM
					cTexto += cCRLF
				EndIf
			EndIf

			//Se Ambiente for Homologacao		
			If cAmbiente == "2"
				cTexto += cCRLF
				cTexto += (TAG_CENTER_INI + TAG_CONDEN_INI + "EMITIDA EM AMBIENTE DE HOMOLOGA��O � SEM VALOR FISCAL" + TAG_CONDEN_FIM + TAG_CENTER_FIM)
				cTexto += Replicate(cCRLF,2)
			EndIf

			If lContigen
				cTexto += cCRLF
				cTexto += (TAG_CENTER_INI + TAG_NEGRITO_INI + "EMITIDA EM CONTING�NCIA" + TAG_NEGRITO_FIM + TAG_CENTER_FIM)
				cTexto += cCRLF
				cTexto += (TAG_CENTER_INI + cTagCondIni + "Pendente de autoriza��o" + cTagCondFim + TAG_CENTER_FIM)
				cTexto += Replicate(cCRLF,2)
			EndIf

			if lNFe //-- TBC-GO Acrescimo para impressao Danfinha NF-e para SIGALOJA
			
				if "EPSON" $ cModelo
					cTexto += cCRLF
					cTexto += TAG_CENTER_INI
					cTexto += (cTagCondIni + TAG_NEGRITO_INI + "Chave de Acesso (em QRCode)" + TAG_NEGRITO_FIM + cTagCondFim)
					cTexto += TAG_CENTER_FIM
					cTexto += cCRLF
				endif
			Endif
			cTexto	+= TAG_CENTER_INI
			If lSTImPFNfce
				cImgQrCode	:= LjRetQrCd( oNfce, cAmbiente,	cModelo, lContigen, lNFe )
			Else
				cTexto	+= LjRetQrCd( oNfce, cAmbiente,	cModelo, lContigen, lNFe )
			EndIf
			cTexto	+= TAG_CENTER_FIM
			cTexto	+= cCRLF

			/*
				DIVISAO IX � Mensagem de Interesse do Contribuinte
			*/
			If Type("oNfce:_NFE:_INFNFE:_INFADIC") == "O" .AND. LjRTemNode(oNfce:_NFE:_INFNFE:_INFADIC, "_INFCPL")

				//para que haja a quebra de linha durante a impressao, separamos cada linha por |
				aInfCpl := StrToKArr(oNfce:_NFE:_INFNFE:_INFADIC:_INFCPL:TEXT, "|")
				nInfCpl := Len( aInfCpl )	//quantidade de quebra de linhas
				
				cTextoAux := ""

				For nY := 1 to nInfCpl
					cTextoAux += (cTagCondIni + aInfCpl[nY] + cTagCondFim)
					If nY <> nInfCpl					
						cTextoAux += cCRLF
					EndIf
				Next
				cTexto += (TAG_CENTER_INI + cTextoAux + TAG_CENTER_FIM)
				cTexto += cCRLF
			EndIf		

			//
			// Salta linha extra
			//
			For nX := 1 to nSaltoLn
				cTexto += cCRLF
			Next nX
		
		endif

		//----------------
		// Imprime o DANFE
		//----------------
		If !lSTImPFNfce .And. lImpComum// Impressora Laser
			U_LOJRNFCe(	oNFCe		, oProt		, nDecimais	, aFormas	,;
						cProtAuto	, lContigen	, cDtHoraAut, aEmitNfce	,; 
						aDestNfce	, aIdNfce	, aPagNfce	, aItemNfce	,; 
						aTotal		, cChvNFCe	, Nil       , aItensNFCe,;
						cXMLProt	, oMyPrint ) //TBC-GO Pra quando passar o oMyPrint
			nRetImp := 0 
		Else //Imprime N�o Fiscal
			
			If lSTImPFNfce
				STImPFNfce(@{"I",cTexto,lPos,cImgQrCode})
			Else
				//
				//Inclui a TAG que Faz o corte do papel, apos a impressao da DANFE
				//
				If lGuil
					cTexto += (TAG_GUIL_INI+TAG_GUIL_FIM)	//aciona a guilhotina
				EndIf
				
				If lPos
					LJGrvLog(Nil, "Envia o texto para a impressao final (STWPrintTextNotFiscal)")
					
					lImpConting := .F.
					If lClasImpNfce
						//Se retorno for falso, n�o houve impress�o em contingencia
						lImpConting := oLojINfce:ImpMsgCon(lContigen, @cTexto, @nRetImp)
					EndIf
							
					If !lImpConting
						nRetImp := STWPrintTextNotFiscal(cTexto)
					EndIf
					
					LJGrvLog(Nil, "Retorno do envio do texto para a impressao final (STWPrintTextNotFiscal)")
				Else
					//Tratamento paliativo para impressora Bematech, ate a solucao de problema de comunicacao ppor parte da BEMATECH
					nRetImp := 999
					lSaiImp := .F.
					
					While nRetImp <> 0 .And. !lSaiImp .And. LjAskImp(nRetImp)
						LJGrvLog(Nil, "Envia o texto para a impressao final (INFTexto)")
						
						lImpConting := .F.
						If lClasImpNfce
							//Se retorno for falso, n�o houve impress�o em contingencia
							lImpConting := oLojINfce:ImpMsgCon(lContigen, @cTexto, @nRetImp)
						EndIf
							
						If !lImpConting
							nRetImp := INFTexto(cTexto)  //Envia comando para a Impressora
						EndIf
													
						If nMVNFCEIMP == 1 .And. nRetImp <> 0 .And. !MsgYesNo("Houve erro na impress�o, deseja tentar imprimir novamente ?", "Aten��o")
							lSaiImp := .T.
							LjGrvLog( Nil,	" Impress�o da NFC-e est� como n�o obrigat�rio [MV_NFCEIMP igual a 1], " +; 
											" houve erro na impress�o do comprovante e usu�rio optou por sair sem imprimir  ")
						EndIf
						
						LJGrvLog(Nil, "Retorno do envio do texto para a impressao final (INFTexto)")
					End
				EndIf
			EndIf
		EndIf

	EndIf

RECOVER
	lRet := .F.

END SEQUENCE

If lRet .And. nMVNFCEIMP == 2 //Impressao do comprovante de NFC-e da venda: 1=Opcional; 2=Obrigatorio;
	If nRetImp == 0 
		lRet := .T. //Sucesso
	Else
		lRet := .F. //Problema
	EndIf
EndIf

//TBC - Erro: [STDProductBasket] A validacao do campo L1_KEYNFCE nao foi respeitada. Tipo: C valor: NFe52191005443159000102650050002115841100267992 Tamanho: 47
cChvNFCe := Left(cChvNFCe,TamSx3("L1_KEYNFCE")[1])
aRet := { lRet,cChvNFCe,nVlrTotal }

LJGrvLog(Nil, "Retorno da funcao LjRDNFNFCe", aRet)

Return  aRet

//--------------------------------------------------------
/*{Protheus.doc} LjRTemNode
Verifica se existe o n� no XML

@author  Varejo
@version P11.8
@since   02/02/2016
@return	 lRet - existe ? 
*/
//--------------------------------------------------------
Static Function LjRTemNode(oObjeto,cNode)
Local lRet := .F.

lRet := (XmlChildEx(oObjeto,cNode) <> NIL)

Return lRet

//--------------------------------------------------------
/*{Protheus.doc} LjUTCtoLoc

@author  Varejo
@version P11.8
@since   02/02/2016
@return	 aRet, array,  
*/
//--------------------------------------------------------
Static Function LjUTCtoLoc(cDataUTC)

Local dData			:= Nil
Local cHoraMin		:= ""
Local cSegundos		:= ""
Local cTZD			:= ""
Local nTZD			:= 0
Local dDataLocal	:= Nil
Local cHoraLocal	:= ""
Local nHoraLocal	:= 0
Local cTZDLocal		:= ""
Local nTZDLocal		:= 0
Local nHoraUTC		:= 0
Local cGMTByUF		:= ""

Local aRet			:= {}
Local aHoraLocal	:= {}

Default cDataUTC 	:= ""

dData 		:= CtoD( SubStr(cDataUTC,9,2) + "/" + SubStr(cDataUTC,6,2) + "/" + SubStr(cDataUTC,1,4) ) //ex: DD/MM/AAAA
cHoraMin	:= SubStr( cDataUTC, 12, 05 )	//ex: hora e minuto do horario ex: 00:00:xx
cSegundos	:= SubStr( cDataUTC, 18, 02 )	//ex: segundos do horario ex: xx:xx:00
cTZD		:= SubStr( cDataUTC, 20, 06 )	//ex: -03:00 
nTZD		:= Val( cTZD )					//ex: -3

/*
	Fuso horario zero (somamos o TZD para obter o fuso horario zero)
*/
nHoraUTC := Val( StrTran(cHoraMin, ":", ".") )
nHoraUTC := nHoraUTC + (nTZD*(-1))

/*
	Fuso horario local
*/
cGMTByUF := SubStr(FwGMTByUF(), 1, 6)
cTZDLocal := SuperGetMV("MV_NFCEUTC",,cGMTByUF)
nTZDLocal := Val(cTZDLocal)

nHoraLocal := nHoraUTC + nTZDLocal

If nHoraLocal >= 24
	nHoraLocal := nHoraLocal - 24
	dDataLocal := dData += 1
Else
	dDataLocal := dData
EndIf

// convertemos a hh:mm para o formato Caracter
cHoraLocal := cValToChar(nHoraLocal)

// tratamos as horas e minutos
aHoraLocal := StrToKArr(cHoraLocal, ".")

aHoraLocal[1] := PadL(aHoraLocal[1], 2, "0")		//acrescenta 0 no inicio da hora
If Len(aHoraLocal) > 1
	aHoraLocal[2] := PadR(aHoraLocal[2], 2, "0")	//acrescenta 0 no final dos minutos
Else //se for hora fechada (ex: 08:00), o array somente vai ter uma posi��o, sendo assim, adicionamos 00 aos Minutos
	Aadd(aHoraLocal, PadR(0, 2, "0"))				//acrescenta 0 no final dos minutos
EndIf

// transforma no formato hh:mm:ss
cHoraLocal := aHoraLocal[1] + ":" + aHoraLocal[2] + ":" + cSegundos

Aadd(aRet, dDataLocal)
Aadd(aRet, cHoraLocal)
Aadd(aRet, cTZDLocal)

Return aRet

//--------------------------------------------------------
/*{Protheus.doc} LjRetQrCd
Retorno do QrCode para impress�o

@author  Varejo
@version P12
@since   09/03/2016
@return	 cRet - qrCode para impress�o 
*/
//--------------------------------------------------------
Static Function LjRetQrCd(	oNfce,	cAmbiente, 	cModelo,  lContigen, lNFe)
Local cKeyQRCode 	:= ""
Local cRet		 	:= ""
Local lSTImPFNfce	:= ExistFunc("STImPFNfce") .And. STImPFNfce()
Local aParams	 	:= {}
Local cCRLF			:= chr(10)

Default	lContigen	:= .F.
Default lNFe		:= Substr(oNfce:_NFE:_INFNFE:_ID:Text,24,02) == "55"

/*
	DIVISAO V � Informa��es da Consulta via QR Code
	A imagem do QR Code poder� ser CENTRALIZADA (conforme o rdmake) ou
	impressa � esquerda das informa��es exigidas nas Divis�es VI e VII
*/
if lNFe 

	cKeyQRCode := Right(oNfce:_NFE:_INFNFE:_ID:Text,12)	//-- 44

	//-- TBC-GO Acrescimo para impressao Danfinha NF-e para SIGALOJA
	//Nova Tentativa impressora EPSON: linguagem da impressora
	//cTexto += cCRLF + CHR(29) + CHR(107) + CHR(73) + CHR(52)+CHR(52) + Left(cChvNFCe,44) + cCRLF//GS k I n(len=44) data 
	if "EPSON" $ cModelo
		cTexto += TAG_CENTER_INI
		cTexto += TAG_QRCODE_INI 
		cTexto += Left(cKeyQRCode,44) 
		cTexto += (TAG_LMODULO_INI + '5' + TAG_LMODULO_FIM)
		ctexto += TAG_QRCODE_FIM
		cTexto += TAG_CENTER_FIM
		cTexto += cCRLF
	else
		cRet := MTAG_CODABAR_INI
		cRet += Left(cKeyQRCode,44)
		cRet += MTAG_CODABAR_FIM
		cRet += cCRLF

		cRet += cCRLF
		cRet += TAG_COD128_INI
		cRet += Left(cKeyQRCode,44)
		cRet += TAG_COD128_FIM
		cRet += cCRLF
		
		cRet += cCRLF
		cRet += TAG_CODE39_INI
		cRet += Left(cKeyQRCode,44)
		cRet += TAG_CODE39_INI
		cRet += cCRLF	

		cRet += cCRLF
		cRet += TAG_CODE93_INI
		cRet += Left(cKeyQRCode,44)
		cRet += TAG_CODE93_FIM
		cRet += cCRLF
	endif
	
Else
	cKeyQRCode := LjNFCeQRCo(oNFCe, cAmbiente, lContigen)
	cRet := TAG_QRCODE_INI
	cRet += cKeyQRCode
	cRet += INFTamQrCd(cModelo,"NFCE")
	cRet += TAG_QRCODE_FIM
EndIf

If lSTImPFNfce
	aParams := {"Q",cKeyQRCode,cRet}
	STImPFNfce(@aParams)
	cRet := aParams[3]
EndIf		

Return cRet

//---------------------------------------------------------------------
/*/{Protheus.doc} RetIBGE
Retorna o codigo da UF segundo o IBGE ou a propria UF
@author  eduardo.sales
@since   13/04/2018
@version 12.1.17
@param	 nTipo - indica qual informacao sera retornada (1-codigo ou 2-UF)
@param	 cParam - indica a informacao a ser pesquisada
@param	 cCodMun - XML transformado em objeto atraves da funcao XMLParser
/*/
//---------------------------------------------------------------------
Static Function RetIBGE( nTipo, cParam, cCodMun)

Local nPos		:= 0	//posi��o de um determinado elemento no array
Local aUF		:= {}	//array com os c�digos das UF
Local cRet		:= ""

Default nTipo	:= 2	//1-retorna UF 2-retorna Codigo IBGE
Default cParam	:= ""	//UF ou Codigo IBGE
Default cCodMun := ""	//Codigo do Municipio

Aadd( aUF, {"RO","11"} )
Aadd( aUF, {"AC","12"} )
Aadd( aUF, {"AM","13"} )
Aadd( aUF, {"RR","14"} )
Aadd( aUF, {"PA","15"} )
Aadd( aUF, {"AP","16"} )
Aadd( aUF, {"TO","17"} )
Aadd( aUF, {"MA","21"} )
Aadd( aUF, {"PI","22"} )
Aadd( aUF, {"CE","23"} )
Aadd( aUF, {"RN","24"} )
Aadd( aUF, {"PB","25"} )
Aadd( aUF, {"PE","26"} )
Aadd( aUF, {"AL","27"} )
Aadd( aUF, {"MG","31"} )
Aadd( aUF, {"ES","32"} )
Aadd( aUF, {"RJ","33"} )
Aadd( aUF, {"SP","35"} )
Aadd( aUF, {"PR","41"} )
Aadd( aUF, {"SC","42"} )
Aadd( aUF, {"RS","43"} )
Aadd( aUF, {"MS","50"} )
Aadd( aUF, {"MT","51"} )
Aadd( aUF, {"GO","52"} )
Aadd( aUF, {"DF","53"} )
Aadd( aUF, {"SE","28"} )
Aadd( aUF, {"BA","29"} )
Aadd( aUF, {"EX","99"} )

nPos := aScan( aUF, {|x| x[nTipo] == cParam} )
If nPos > 0
	cRet := aUF[nPos][nTipo]
	 // Se retornar codigo IBGE, pode concatenar com o Codigo do Municipio
 	If nTipo = 2
 		cRet += AllTrim(cCodMun)
	EndIf
EndIf

Return cRet

//---------------------------------------------------------------------
/*/{Protheus.doc} LJDNFNFE
Faz a impressao do DANFE NFe Simplificada em uma impressora nao-fiscal

@author  eduardo.sales
@since   13/04/2018
@version 12.1.17
@param	 oNFE - XML transformado em objeto atraves da funcao XMLParser
@param	 cCodAutSef - Protocolo de Autoriza��o da NFe
@param	 dDtReceb - Data de Recebimento da NFe pelo SEFAZ
@param	 cDtHrRecCab - Hora de Recebimento da NFe pelo SEFAZ
/*/
//---------------------------------------------------------------------
User Function LJDNFNFE(oNFe, cCodAutSef, dDtReceb, cDtHrRecCab)

Local cTexto		:= ""		// Texto de impress�o da DANFE
Local cTxtAux		:= ""
Local nX			:= 0		// Contador
Local aColDiv2		:= {}		// Colunas para impress�o da DANFE
Local nCodDesc		:= 0		// Descri��o do Produto
Local cItemPic		:= ""		// Picture utilizada para o Valor Unitario
Local cConteudo		:= ""
Local nTamDesc		:= 0		// Tamanho do campo de Descri��o
Local cLinha		:= ""		// Linha a ser impressa
Local lImpDesc		:= .T.		// Variaveis de controle da impressao da Descricao
Local nIniDesc		:= 0		
Local nFimDesc		:= 0
Local nConteudo 	:= 0
Local nColunas		:= 48		// Numero de Colunas
Local lContinua		:= .F.		
Local nRet			:= 1

Default oNFe		:= Nil
Default cCodAutSef	:= Nil
Default dDtReceb	:= Nil
Default cDtHrRecCab	:= Nil

If ExistFunc("LjAbrImp")
	lContinua := LjAbrImp()
EndIf

If lContinua
	
	cTexto += CRLF
	cTexto += TAG_CENTER_INI + TAG_NEGRITO_INI + "DANFE SIMPLIFICADO" + TAG_NEGRITO_FIM + TAG_CENTER_FIM
	cTexto += CRLF

	cTxtAux := SubStr(oNFe:_NFe:_InfNfe:_ID:TEXT,4)

	//Codigo de Barras
	cTexto += TAG_CENTER_INI + TAG_COD128_INI + cTxtAux + TAG_COD128_FIM + TAG_CENTER_FIM

	cTexto += TAG_CENTER_INI
	cTexto += TAG_CONDEN_INI

	//1111 2222 3333 4444 5555 6666 7777 8888 9999 0000 1111
	For nX := 1 to 44 Step 4
		cTexto += SubStr( cTxtAux, nX , 4 ) + " "				
	Next

	cTexto += TAG_CONDEN_FIM
	cTexto += TAG_CENTER_FIM
	cTexto += Replicate(CRLF,2)
	cTexto += TAG_NEGRITO_INI + "Protocolo de Autoriza��o:" + TAG_NEGRITO_FIM
	cTexto += CRLF
	cTexto += cCodAutSef + " " + DTOC(dDtReceb) + " " + AllTrim(SubStr(cDtHrRecCab, 0, 8))
	cTexto += Replicate(CRLF,2)

	cTexto += TAG_NEGRITO_INI + "EMITENTE" + TAG_NEGRITO_FIM
	cTexto += CRLF
	cTexto += oNFe:_NFe:_InfNfe:_Emit:_xNome:Text
	cTexto += CRLF
	cTexto += RetIBGE(1,oNFe:_NFe:_InfNfe:_Emit:_EnderEmit:_UF:Text)
	cTexto += CRLF
	cTexto += "CNPJ: " + Transform( oNFe:_NFe:_InfNfe:_Emit:_CNPJ:TEXT, "@R 99.999.999/9999-99" )
	cTexto += CRLF
	cTexto += "Inscri��o Estadual: " + IIf( ValType(XMLChildEx(oNFe:_NFe:_InfNfe:_Emit, "_IE"))=="O", oNFe:_NFe:_InfNfe:_Emit:_IE:TEXT, "" )
	cTexto += Replicate(CRLF,2)

	cTexto += TAG_NEGRITO_INI + "DADOS GERAIS DA NF-E" + TAG_NEGRITO_FIM
	cTexto += CRLF
	cTexto += "Tipo de Opera��o: Sa�da"
	cTexto += CRLF
	cTexto += "N�mero da NF-e: " + StrZero( Val(oNFe:_NFe:_InfNfe:_IDE:_NNf:Text), 9 ) + " S�rie: " + oNFe:_NFe:_InfNfe:_IDE:_Serie:Text
	cTexto += CRLF
	cTexto += "Data de Emiss�o: " + SubStr(oNFe:_NFe:_InfNfe:_IDE:_DHEmi:TEXT,9,2) + "/" + SubStr(oNFe:_NFe:_InfNfe:_IDE:_DHEmi:TEXT,6,2) + "/" + SubStr(oNFe:_NFe:_InfNfe:_IDE:_DHEmi:TEXT,1,4)
	cTexto += Replicate(CRLF,2)

	cTexto += TAG_NEGRITO_INI + "DESTINAT�RIO" + TAG_NEGRITO_FIM
	cTexto += CRLF
	cTexto += oNFe:_NFe:_InfNfe:_Dest:_xNome:TEXT
	cTexto += CRLF
	cTexto += RetIBGE(1, oNFe:_NFe:_InfNfe:_Dest:_EnderDest:_UF:Text)
	cTexto += CRLF

	If ValType(XMLChildEx(oNFe:_NFe:_InfNfe:_Dest, "_CNPJ")) == "O"
		cTexto += "CNPJ: " + TransForm(oNFe:_NFe:_InfNfe:_Dest:_CNPJ:TEXT,"@R 99.999.999/9999-99")
	ElseIf ValType(XMLChildEx(oNFe:_NFe:_InfNfe:_Dest, "_CPF")) == "O"
		cTexto += "CPF: " + TransForm(oNFe:_NFe:_InfNfe:_Dest:_CPF:TEXT,"@R 999.999.999-99")
	Else
		cTxtAux := Space(14)
	EndIf

	cTexto += CRLF

	xRet := XMLChildEx(oNFe:_NFe:_InfNfe, "_DET")
	If ValType(xRet) == "O"
		xRet := {xRet}
	EndIf

	cTexto += CRLF
	cTexto += TAG_NEGRITO_INI + "DESCRI��O DOS PRODUTOS/SERVI�OS" + TAG_NEGRITO_FIM
	cTexto += CRLF
	cTexto += (TAG_NEGRITO_INI + TAG_CENTER_INI)
	cTexto += "Descri��o             Qtd UN Vlr Unit. Vlr Total"	//48 colunas
	cTexto +=  (TAG_CENTER_FIM + TAG_NEGRITO_FIM)
	cTexto += CRLF

	// ATENCAO: se alterar algum valor do array, deve-se alterar o cabecalho acima tambem
	Aadd(aColDiv2, 20)	// Descricao
	Aadd(aColDiv2, 05)	// Qtd
	Aadd(aColDiv2, 02)	// Un
	Aadd(aColDiv2, 08)	// VlUnit.
	Aadd(aColDiv2, 09)	// VlTotal

	// soma das colunas
	nCodDesc := aColDiv2[1]

	//obtemos a Picture que sera utilizada para o valor unitario
	cItemPic := "@E " + Right( "@E 999,999,999.99", aColDiv2[5] )

	For nX := 1 to Len(xRet)

		cLinha := ""

		// Descricao				
		cConteudo := xRet[nX]:_PROD:_XPROD:TEXT
		nTamDesc := Len( cConteudo )

		// Variaveis de controle da impressao da Descricao
		lImpDesc := .T.
		nIniDesc := 1
		nFimDesc := aColDiv2[1] + aColDiv2[2] + aColDiv2[3] + aColDiv2[4] + aColDiv2[5] + 4 //4 espa�os separadores

		While lImpDesc

			//agora a linha contem o Codigo e Descricao do produto
			cLinha += SubStr(cConteudo, nIniDesc, nFimDesc)

			//
			//	Se o tamanho do Codigo + Descricao do produto ultrapassar a coluna Descricao, 
			//	entao a impressao das informacoes do item continuara na proxima linha a partir da coluna Codigo
			//				
			If Len(cLinha) > nCodDesc

				//texto a ser impresso
				cLinha := PadR(cLinha, nColunas)
				cTexto += (TAG_CENTER_INI + cLinha + TAG_CENTER_FIM)
				cTexto += CRLF

				//
				// Controle para a PROXIMA linha
				//
				cLinha := ""
			
				//subtraimos do tamanho da Descricao, o conteudo ja impresso
				nTamDesc -= nFimDesc
			
				//somamos a posicao inicial a ser lido da Descricao, o conteudo ja impresso
				nIniDesc += nFimDesc

				If nTamDesc < 1
					//toda a descricao foi impressa, entao podemos continuar a imprimir as outras informacoes
					nFimDesc := 0
				ElseIf nTamDesc > nCodDesc
					//a descricao restante ultrapassa a coluna Descricao, entao ela usara a linha toda
					nFimDesc := nColunas
				Else
					//a descricao restante somente utilizara as colunas Codigo e Descricao
					nFimDesc := nCodDesc
				EndIf
		
			Else
			
				//nao sera necessario adicionar uma linha para impressao das outras informacoes dos itens
				lImpDesc := .F.
				cLinha := PadR( cLinha, nCodDesc ) + " "
			EndIf

		EndDo

		// Qtd - quantidade
		nConteudo := Val( xRet[nX]:_PROD:_QCOM:TEXT )
		cConteudo := cValToChar(nConteudo)
		cLinha += PadL(cConteudo, aColDiv2[2]) + " "

		// Un - unidade de medida
		cLinha += PadL(xRet[nX]:_PROD:_UCOM:TEXT, aColDiv2[3]) + " "

		// VlUnit. - valor unitario
		nConteudo := Val( xRet[nX]:_PROD:_VUNCOM:TEXT )
		cConteudo := Transform(nConteudo, cItemPic) + " "
		cLinha += cConteudo

		// VlTotal - valor total
		nConteudo := Val( xRet[nX]:_PROD:_VPROD:TEXT )
		cConteudo := Transform(nConteudo, '@E 999,999.99')
		cLinha += cConteudo

		cTexto += (TAG_CENTER_INI + cLinha + TAG_CENTER_FIM)
		cTexto += CRLF
	Next

	cTexto += "VALOR TOTAL DA NF-e: " + AllTrim( Transform(Val(oNFe:_NFe:_InfNfe:_Total:_ICMSTOT:_vNF:TEXT),"@E 9,999,999,999,999.99") )
	cTexto += CRLF + CRLF + CRLF

	// Imprime a DANFE Simplificada
	While nRet <> 0
		nRet := INFTexto(cTexto)
		INFCutPpr()

		If nRet <> 0
			If !MsgYesNo("N�o foi poss�vel imprimir a DANFE Simplificada, tentar novamente?")
				nRet := 0
			EndIf
		EndIf
	End
EndIf

Return .T.

//--------------------------------------------------------
/*{Protheus.doc} LjDfRetFrm
TBC-GOCarrega as formas de pagamento padr�o 

@author  Varejo
@version P11.8
@since   27/01/2016
@return	 
*/
//--------------------------------------------------------
Static Function MyLjDfRetFrm()
Local aFormas := {}

//Declaramos as Formas de Pagamento conforme NT2013.005 v1.03           
Aadd( aFormas, {"Dinheiro         ","01", "R$"} )
Aadd( aFormas, {"Cheque           ","02", "CH"} )
Aadd( aFormas, {"Cartao de Credito","03", "CC"} )
Aadd( aFormas, {"Cartao de Debito ","04", "CD"} )
Aadd( aFormas, {"Credito Loja     ","05", "NB"} )
Aadd( aFormas, {"Vale Alimentacao ","10", "VA"} )
Aadd( aFormas, {"Vale Refeicao    ","11", "VR"} )
Aadd( aFormas, {"Vale Presente    ","12", "VP"} )
Aadd( aFormas, {"Vale Combustivel ","13", "RP"} )
Aadd( aFormas, {"Boleto Bancario  ","15", "BOL"} )
Aadd( aFormas, {"Sem Pagamento    ","90", ""} )
Aadd( aFormas, {"Outros           ","99", ""} )
Aadd( aFormas, {"PIX              ","17", "PX"} )
Aadd( aFormas, {"Pagto Digital    ","18", "PD"} )

Aadd( aFormas, {"Nota a Prazo     ","05", "NP"} )
Aadd( aFormas, {"Carta Frete      ","05", "CF"} )
Aadd( aFormas, {"CTF		      ","99", "CT"} )
Aadd( aFormas, {"Credito Loja     ","12", "NCC"} )
Aadd( aFormas, {"Credito Loja     ","12", "RA"} )

Return aFormas

//TBC-GO (copiado parte da fun��o do fonte LONNFCE)
/*/{Protheus.doc} LjDANFENFe
Prepara os objetos de impressao e realiza a impressao do DANFE NF-e
@type		function
@author  	Varejo
@version 	P12
@since   	20/11/2016
@return  	Nil
@obs     	Baseada na funcao SPEDDANFE() (SPEDNFE.PRX)
/*/
Static Function LjDANFENFe()

Local cFilePrint	:= ""	//nome do arquivo de impressao do DANFE
Local cChave		:= ""	//valor da chave pesquisada no Profile do usuario
Local cIDEnt		:= ""	//codigo da entidade do servidor TSS
Local cSession		:= GetPrinterSession()
Local lRetAux		:= .T.
Local oDANFE		:= Nil	//objeto da classe FwMsPrinter
Local oSetup		:= Nil	//objeto da classe FwPrintSetup

Local nFlags		:= 0	//indica quais opcoes estarao disponiveis na configuracao da impressao
Local nDestination	:= 1	//SERVER
Local nOrientation	:= 1	//PORTRAIT
Local nPrintType	:= 6	//PDF
Local aDevice		:= {}
Local aImpSmart		:= {}
Local lLoja			:= .T.	//indica se eh loja	

//Entidade configurada no servidor TSS
cIDEnt := LjTSSIDEnt("55")

//Nome do arquivo que sera impresso: DANFE_ + ENTIDADE + AAAAMMSS + HHMMSS   
cFilePrint := "DANFE_" + cIDEnt + DtoS(MSDate()) + StrTran(Time(),":","")

//
// Configuracoes de Impressao baseada no Profile
//
cChave := FWGetProfString(cSession, "LOCAL", "CLIENT", .T.)//Usuario tem que alterar manualmente para impressora padrao "SERVER"
If cChave <> "CLIENT"	
	nDestination := 2	//CLIENT
EndIf

cChave := FWGetProfString(cSession, "ORIENTATION", "PORTRAIT", .T.)
If cChave <> "PORTRAIT"
	nOrientation := 2	//LANDSCAPE
EndIf

aDevice := {"DISCO","SPOOL","EMAIL","EXCEL","HTML","PDF"}
cChave := FWGetProfString(cSession, "PRINTTYPE", "SPOOL", .T.)
If Empty(cChave)
	cChave := "PDF"
EndIf
nPrintType := aScan( aDevice, {|x| x == cChave} )

//
// FWPrintSetup
//
nFlags := PD_ISTOTVSPRINTER + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN // indica quais opcoes estarao disponiveis
oSetup := FWPrintSetup():New(nFlags, "DANFE")

oSetup:SetPropert(PD_PRINTTYPE   , nPrintType)
oSetup:SetPropert(PD_ORIENTATION , nOrientation)
oSetup:SetPropert(PD_DESTINATION , nDestination)
oSetup:SetPropert(PD_MARGIN      , {60,60,60,60})
oSetup:SetPropert(PD_PAPERSIZE   , 2)
oSetup:CQTDCOPIA := "01"

//
// FWMsPrinter
//
oDANFE := FWMSPrinter():New(cFilePrint, nPrintType /*IMP_PDF*/, .F. /*lAdjustToLegacy*/, /*cPathInServer*/, .T.) 

oDANFE:SetCopies( Val(oSetup:CQTDCOPIA) )

If GetRemoteType() <> REMOTE_LINUX
	//Carrega as Impressoras do Smartclient para facilitar a impressao sem escolha
	aImpSmart := GetImpWindows(.F.)
	
	//Seta a impressora padrao Windows
	if !Empty(aImpSmart)
		oDANFE:nDevice := IMP_SPOOL
		oSetup:aOptions[PD_VALUETYPE] := aImpSmart[01]
	endif
EndIf

//
// Ponto de Entrada para customizar os objetos de impressao
//
If ExistBlock( "SPNFESETUP" )
	Execblock( "SPNFESETUP" , .F. , .F. , {oDANFE, oSetup} )
Else		
	// Interface para o usuario configurar os parametros de impressao
	lRetAux := oSetup:Activate() == PD_OK
	oDANFE:SetCopies( Val(oSetup:CQTDCOPIA) )
EndIf

If lRetAux

	//
	// Atualiza os parametros no Profile
	//
	FwWriteProfString( cSession, "LOCAL"      , If(oSetup:GetProperty(PD_DESTINATION)==1 ,"SERVER"    ,"CLIENT"    ), .T. )
	FwWriteProfString( cSession, "PRINTTYPE"  , If(oSetup:GetProperty(PD_PRINTTYPE)==2   ,"SPOOL"     ,"PDF"       ), .T. )
	FwWriteProfString( cSession, "ORIENTATION", If(oSetup:GetProperty(PD_ORIENTATION)==1 ,"PORTRAIT"  ,"LANDSCAPE" ), .T. )

	LjGrvLog( SL1->L1_NUM," Realiza a impress�o do DANFE",  )

	U_PrtNFeSEF(cIDEnt, Nil, Nil, oDANFE, oSetup, cFilePrint, lLoja)

endif

Return Nil
