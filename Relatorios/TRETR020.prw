#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"
#include "fwprintsetup.ch"

#define DMPAPER_A4 9 // A4 210 x 297 mm
#define IMP_PDF 6 // PDF

/*/{Protheus.doc} TRETR020
Geração de relatório vendas online baseado nos abastecimentos realizados no posto (tabela MID) e também o resumo de vendas por PDV (tabela SL2).

@type function
@version 12.1.33
@author Pablo Nunes
@since 04/04/2022
/*/
User Function TRETR020()

////////////////////// FONTES PARA SEREM UTILIZADAS NO RELATORIO ///////////////////////////

	Private oFont6		:= TFONT():New("Arial",,6,.T.,.F.,5,.T.,5,.T.,.F.	) //Fonte 6 Normal
	Private oFont6N 	:= TFONT():New("Arial",,6,,.T.,,,,.T.,.F.			) //Fonte 6 Negrito
	Private oFont8		:= TFONT():New('Arial',,8,,.F.,,,,.F.,.F.		) //Fonte 9 Normal
	Private oFont8N		:= TFONT():New('Arial',,8,,.T.,,,,.F.,.F.		) //Fonte 9 Negrito
	Private oFont8NI	:= TFONT():New('Times New Roman',,8,,.T.,,,,.F.,.F.,.T.) //Fonte 8 Negrito e Itálico
	Private oFont9		:= TFONT():New('Arial',,9,,.F.,,,,.F.,.F.	) //Fonte 9 Normal
	Private oFont9N	    := TFONT():New('Arial',,9,,.T.,,,,.F.,.F.	) //Fonte 9 Negrito
	Private oFont10		:= TFONT():New('Arial',,10,,.F.,,,,.F.,.F.	) //Fonte 10 Normal
	Private oFont10N	:= TFONT():New('Arial',,10,,.T.,,,,.F.,.F.	) //Fonte 10 Negrito
	Private oFont11N	:= TFONT():New('Arial',,11,,.T.,,,,.F.,.F.	) //Fonte 11 Negrito
	Private oFont12	    := TFONT():New('Arial',,12,,.F.,,,,.F.,.F.	) //Fonte 12 Normal
	Private oFont12N	:= TFONT():New('Arial',,12,,.T.,,,,.F.,.F.	) //Fonte 12 Negrito
	Private oFont14N	:= TFONT():New('Times New Roman',,16,,.T.,,,,.F.,.F.	) //Fonte 14 Negrito
	Private oFont14NI	:= TFONT():New('Times New Roman',,14,,.T.,,,,.F.,.F.,.T.) //Fonte 14 Negrito e Itálico
	Private oFont16N	:= TFONT():New('Arial',,16,,.T.,,,,.F.,.F.	) //Fonte 16 Negrito
	Private oFont16NI	:= TFONT():New('Times New Roman',,16,,.T.,,,,.F.,.F.,.T.) //Fonte 16 Negrito e Itálico

////////////////////////////////////////////////////////////////////////////////////////////
	Private cStartPath
	Private nLin 		:= 50
	Private cArquivo	:= "TRETR020_"+DTOS(Date())+SUBSTR(Time(),1,2)+SUBSTR(Time(),4,2)+SUBSTR(Time(),7,2)
	Private oPrint	 	:= Nil
	Private oBrush		:= TBrush():New(,CLR_HGRAY)
	Private nPagina		:= 1

	Private cPerg		:= "TRETR020"
	Private oDlg

	If !fValidPerg()
		Return
	Endif

	oPrint := FwMSPrinter():New(cArquivo,IMP_PDF,.T.,,.T.,,,,.T.,.F.)
	oPrint:SetDevice(IMP_PDF)
	oPrint:SetResolution(72)
	oPrint:SetPortrait() // ou SetLandscape()
	oPrint:SetPaperSize(DMPAPER_A4)
	oPrint:SetMargin(0,0,0,0)
    oPrint:Setup() //Tela de configurações

	AjuStatusMID() //Ajuste STATUS de abastecimentos da tabela (MID)

	Processa({|| fCorpoRel() })

Return()

/*/{Protheus.doc} fValidPerg
Perguntas SX1

@type function
@version 12.1.33
@author Pablo Nunes
@since 04/04/2022
/*/
Static Function fValidPerg()

	Local aHelpPor := {}

	U_uAjusSx1(cPerg,"01",OemToAnsi("Período de  ?"),"","","mv_ch1","D",10,0,0,"G","","","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"02",OemToAnsi("Período até ?"),"","","mv_ch2","D",10,0,0,"G","","","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"03",OemToAnsi("Produto de  ?"),"","","mv_ch3","C",tamsx3("B1_COD")[1],0,0,"G","","SB1","","","mv_par03","","","",space(tamsx3("B1_COD")[1]),"","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"04",OemToAnsi("Produto até ?"),"","","mv_ch4","C",tamsx3("B1_COD")[1] ,0,0,"G","","SB1","","","mv_par04","","","",replicate("Z",tamsx3("B1_COD")[1]),"","","","","","","","","","","","",aHelpPor,{},{})

Return Pergunte(cPerg,.T.)

/*/{Protheus.doc} fCabecalho
Função que imprime o cabaçalho do relatório

@type function
@version 12.1.33
@author Pablo Nunes
@since 04/04/2022
/*/
Static Function fCabecalho()

	oPrint:StartPage() // Inicia uma nova pagina
	cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")

	nLin:=100

	//Impressao da Logo
	oPrint:Box(nLin,145,nLin+132,380)
	oPrint:SayBitmap(nLin+45, 170, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 180, 036) //proporção: (L)100 x (A)20

	//Dados da empresa e filtro relatório
	oPrint:Box(nLin,380,nLin+132,1850)
	oPrint:Say(nLin+30, 390, AllTrim(cNomeCom), oFont10N) //SM0->M0_NOMECOM
	oPrint:Say(nLin+70, 390, "Vendas Online", oFont11N)
	oPrint:Say(nLin+110, 390, "Período: "+DtoC(MV_PAR01)+" à "+DtoC(MV_PAR02), oFont10N)

	//Numero da página e data e hora
	oPrint:Box(nLin,1850,nLin+132,2300)
	oPrint:SayAlign(nLin+25, 1850, "Página: " + strzero(nPagina,3), oFont9N,450/*largura*/,50/*altura*/,,2,0)
	oPrint:SayAlign(nLin+65, 1850, DTOC(Date())+" "+Time(), oFont9N,450/*largura*/,50/*altura*/,,2,0)

	nLin+=182

Return()

/*/{Protheus.doc} fCabecAbast
Função que imprime o cabaçalho do relatório: VENDAS DE COMBUSTÍVEIS (BAIXADOS ou PENDENTES)

@type function
@version 12.1.33
@author Pablo Nunes
@since 04/04/2022
/*/
Static Function fCabecAbast(nTipo)

	oPrint:Box(nLin,145,nLin+50,2300)
	If nTipo == 1
		oPrint:SayAlign(nLin+10, 155, "VENDAS DE COMBUSTÍVEIS (BAIXADOS)", oFont10N,2135/*largura*/,50/*altura*/,,2,0)
	Else
		oPrint:SayAlign(nLin+10, 155, "VENDAS DE COMBUSTÍVEIS (PENDENTES)", oFont10N,2135/*largura*/,50/*altura*/,,2,0)
	EndIf

	nLin+=50

	oPrint:Box(nLin,145,nLin+50,415)
	oPrint:SayAlign(nLin+10, 155, "Produto", oFont10N,250/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,415,nLin+50,1225)
	oPrint:SayAlign(nLin+10, 425, "Descrição", oFont10N,790/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,1225,nLin+50,1495)
	oPrint:SayAlign(nLin+10, 1235, "Data", oFont10N,250/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,1495,nLin+50,1900)
	oPrint:SayAlign(nLin+10, 1505, "Litragem", oFont10N,385/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,1900,nLin+50,2300)
	oPrint:SayAlign(nLin+10, 1910, "Valor", oFont10N,385/*largura*/,50/*altura*/,,2,0)

	nLin+=50

Return()

/*/{Protheus.doc} fCabecProd
Função que imprime o cabaçalho do relatório: VENDAS DE PRODUTOS POR PDV

@type function
@version 12.1.33
@author Pablo Nunes
@since 04/04/2022
/*/
Static Function fCabecProd()

	oPrint:Box(nLin,145,nLin+50,1630)
	oPrint:SayAlign(nLin+10, 155, "VENDAS DE PRODUTOS POR PDV", oFont10N,1465/*largura*/,50/*altura*/,,2,0)

	nLin+=50

	oPrint:Box(nLin,145,nLin+50,415)
	oPrint:SayAlign(nLin+10, 155, "PDV", oFont10N,250/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,415,nLin+50,820)
	oPrint:SayAlign(nLin+10, 425, "Nome", oFont10N,385/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,820,nLin+50,1225)
	oPrint:SayAlign(nLin+10, 830, "Quantidade", oFont10N,385/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,1225,nLin+50,1630)
	oPrint:SayAlign(nLin+10, 1235, "Valor", oFont10N,385/*largura*/,50/*altura*/,,2,0)

	nLin+=50

Return()

/*/{Protheus.doc} fRodape
Função para crair o rodapé do relatório

@type function
@version 12.1.33
@author Pablo Nunes
@since 04/04/2022
/*/
Static Function fRodape()

	nLin:=2900

	oPrint:Line(nLin,150,nLin,2300)
	nLin+=20
	oPrint:Say(nLin, 1080, "Microsiga Protheus", oFont8N)
	nLin+=10
	oPrint:Line(nLin,150,nLin,2300)

Return()

/*/{Protheus.doc} fCorpoRel
Função para preencher o relatório

@type function
@version 12.1.33
@author Pablo Nunes
@since 04/04/2022
/*/
Static Function fCorpoRel()

	Local cQuery   	 := ""
	Local nTotLit	 := 0
	Local nTotVal    := 0
	Local aSM0       := {}
	Local nTipo      := 1

	Private oDlgImp
	Private cNomeCom := ""

	If Findfunction("FindClass") .AND. FindClass("FWSM0Util")
		If Empty(Select("SM0"))
			OpenSM0(cEmpAnt)
		EndIf
		aSM0 := FWSM0Util():GetSM0Data()
		nAux := aScan(aSM0, {|x| alltrim(x[1]) == "M0_NOMECOM" })
		cNomeCom := aSM0[nAux][2]
	Else
		DbSelectArea("SM0")
		cNomeCom := SM0->M0_NOMECOM
	EndIf

	fCabecalho()

	//VENDAS DE COMBUSTÍVEIS (BAIXADOS)
	//VENDAS DE COMBUSTÍVEIS (PENDENTES)
	For nTipo:=1 to 2

		If Select("QRYMID") > 0
			QRYMID->(DbCloseArea())
		Endif

		cQuery := "SELECT MID.MID_FILIAL, MID.MID_XPROD, SB1.B1_DESC, MID.MID_DATACO, SUM(MID.MID_LITABA) AS LITRAGEM, SUM(MID.MID_TOTAPA) AS VTOTAL " + CRLF
		cQuery += " FROM "+RetSqlName("MID")+" MID " + CRLF
		cQuery += " LEFT JOIN "+RetSqlName("SB1")+" SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_COD = MID.MID_XPROD) " + CRLF
		cQuery += " WHERE MID.D_E_L_E_T_ = ' ' "  + CRLF
		cQuery += " AND MID.MID_FILIAL = '"+xFilial("MID")+"' " + CRLF
		cQuery += " AND MID.MID_DATACO >= '"+DTOS(MV_PAR01)+"' AND MID.MID_DATACO <= '"+DTOS(MV_PAR02)+"' " + CRLF
		cQuery += " AND MID.MID_XPROD >= '"+MV_PAR03+"' AND MID.MID_XPROD <= '"+MV_PAR04+"' " + CRLF

		If nTipo == 1
			cQuery += " AND (MID.MID_NUMORC	<> 'P     ' AND MID.MID_NUMORC <> 'O     ')"  + CRLF //BAIXADOS
			cQuery += " AND EXISTS ( " //existe nota fiscal
			cQuery += " SELECT 1 "
			cQuery += " FROM SL2010 SL2 "
			cQuery += " WHERE SL2.D_E_L_E_T_ = ' ' "
			cQuery += " AND MID.MID_FILIAL = SL2.L2_FILIAL "
			cQuery += " AND MID.MID_CODABA = SL2.L2_MIDCOD) " + CRLF
			cQuery += " AND MID.MID_AFERIR <> 'S' " + CRLF //desconsidera AFERIÇÕES
		Else
			cQuery += " AND (MID.MID_NUMORC = 'P     ' OR MID.MID_NUMORC = 'O     ') "  + CRLF //PENDENTES
			cQuery += " AND NOT EXISTS ( " //não existe nota fiscal
			cQuery += " SELECT 1 "
			cQuery += " FROM SL2010 SL2 "
			cQuery += " WHERE SL2.D_E_L_E_T_ = ' ' "
			cQuery += " AND MID.MID_FILIAL = SL2.L2_FILIAL "
			cQuery += " AND MID.MID_CODABA = SL2.L2_MIDCOD) " + CRLF
			cQuery += " AND MID.MID_AFERIR <> 'S' " + CRLF //desconsidera AFERIÇÕES
		EndIf

		cQuery += " GROUP BY MID.MID_FILIAL, MID.MID_XPROD, SB1.B1_DESC, MID.MID_DATACO " + CRLF
		cQuery += " ORDER BY MID.MID_FILIAL, MID.MID_DATACO, MID.MID_XPROD " + CRLF

		cQuery := ChangeQuery(cQuery)
		TcQuery cQuery New Alias "QRYMID" // Cria uma nova area com o resultado do query

		fCabecAbast(nTipo)

		While QRYMID->(!EOF())

			If nLin > 2850
				fRodape()
				NovaPagina(nTipo)
			EndIf

			oPrint:Box(nLin,145,nLin+50,415)
			oPrint:SayAlign(nLin+10, 155, QRYMID->MID_XPROD, oFont10,250/*largura*/,50/*altura*/,,0,0)

			oPrint:Box(nLin,415,nLin+50,1225)
			oPrint:SayAlign(nLin+10, 425, QRYMID->B1_DESC, oFont10,790/*largura*/,50/*altura*/,,0,0)

			oPrint:Box(nLin,1225,nLin+50,1495)
			oPrint:SayAlign(nLin+10, 1235, DtoC(StoD(QRYMID->MID_DATACO)), oFont10,250/*largura*/,50/*altura*/,,2,0)

			oPrint:Box(nLin,1495,nLin+50,1900)
			oPrint:SayAlign(nLin+10, 1505, Transform(QRYMID->LITRAGEM, "@E 999,999,999,999.99"), oFont10,385/*largura*/,50/*altura*/,,1,0)

			oPrint:Box(nLin,1900,nLin+50,2300)
			oPrint:SayAlign(nLin+10, 1910, Transform(QRYMID->VTOTAL, "@E 999,999,999,999.99"), oFont10,385/*largura*/,50/*altura*/,,1,0)

			nLin+=50

			nTotLit += QRYMID->LITRAGEM
			nTotVal += QRYMID->VTOTAL

			QRYMID->(DbSkip())

		EndDo

		QRYMID->(DbCloseArea()) // fecha a área criada

		If nLin > 2850
			fRodape()
			NovaPagina(nTipo)
		EndIf

		oPrint:Box(nLin,145,nLin+50,2300)
		oPrint:SayAlign(nLin+10, 155, "Total "+IIF(nTipo==1,"Baixado","Pendente"), oFont10N,1330/*largura*/,50/*altura*/,,0,0)
		oPrint:SayAlign(nLin+10, 1505, Transform(nTotLit, "@E 999,999,999,999.99"), oFont10N,385/*largura*/,50/*altura*/,,1,0)
		oPrint:SayAlign(nLin+10, 1910, Transform(nTotVal, "@E 999,999,999,999.99"), oFont10N,385/*largura*/,50/*altura*/,,1,0)
		nLin+=100
		nTotLit := 0
		nTotVal := 0

	Next nTipo

	//VENDAS DE PRODUTOS POR PDV
	nTipo := 3

	If Select("QRYSL2") > 0
		QRYSL2->(DbCloseArea())
	Endif

	cQuery := "SELECT SL2.L2_FILIAL, SLG.LG_PDV, SLG.LG_NOME, SUM(SL2.L2_QUANT) VQTD, SUM(SL2.L2_VLRITEM) VTOT " + CRLF
	cQuery += " FROM "+RetSqlName("SL2")+" SL2 " + CRLF
	cQuery += " INNER JOIN "+RetSqlName("SLG")+" SLG ON (SLG.D_E_L_E_T_ = ' ' AND SLG.LG_FILIAL = '"+xFilial("SLG")+"' AND SLG.LG_PDV = SL2.L2_PDV) " + CRLF
	cQuery += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_COD = SL2.L2_PRODUTO) " + CRLF
	cQuery += " WHERE SL2.D_E_L_E_T_ = ' ' "  + CRLF
	cQuery += " AND SL2.L2_FILIAL = '"+xFilial("SL2")+"' " + CRLF
	cQuery += " AND SL2.L2_EMISSAO >= '"+DTOS(MV_PAR01)+"' AND SL2.L2_EMISSAO <= '"+DTOS(MV_PAR02)+"' " + CRLF
	cQuery += " AND SL2.L2_PRODUTO >= '"+MV_PAR03+"' AND SL2.L2_PRODUTO <= '"+MV_PAR04+"' " + CRLF
	//cQuery += " AND SB1.B1_GRUPO NOT IN "+FormatIN(SuperGetMV("MV_COMBUS"),"/") + " "  + CRLF //NÃO COMBUSTIVEIS
	cQuery += " AND SL2.L2_PRODUTO NOT IN (SELECT MHZ_CODPRO FROM "+RetSqlName("MHZ")+" MHZ WHERE MHZ.D_E_L_E_T_ = ' ' AND MHZ_FILIAL = '"+xFilial("MHZ")+"') "+ CRLF //NÃO COMBUSTIVEIS
	cQuery += " GROUP BY SL2.L2_FILIAL, SLG.LG_PDV, SLG.LG_NOME " + CRLF
	cQuery += " ORDER BY SL2.L2_FILIAL, SLG.LG_PDV, SLG.LG_NOME " + CRLF

	cQuery := ChangeQuery(cQuery)
	TcQuery cQuery New Alias "QRYSL2" // Cria uma nova area com o resultado do query

	fCabecProd()

	While QRYSL2->(!EOF())

		If nLin > 2850
			fRodape()
			NovaPagina(nTipo)
		EndIf

		oPrint:Box(nLin,145,nLin+50,415)
		oPrint:SayAlign(nLin+10, 155, QRYSL2->LG_PDV, oFont10,250/*largura*/,50/*altura*/,,0,0)

		oPrint:Box(nLin,415,nLin+50,820)
		oPrint:SayAlign(nLin+10, 425, QRYSL2->LG_NOME, oFont10,385/*largura*/,50/*altura*/,,0,0)

		oPrint:Box(nLin,820,nLin+50,1225)
		oPrint:SayAlign(nLin+10, 830, Transform(QRYSL2->VQTD, "@E 999,999,999,999.99"), oFont10,385/*largura*/,50/*altura*/,,1,0)

		oPrint:Box(nLin,1225,nLin+50,1630)
		oPrint:SayAlign(nLin+10, 1235, Transform(QRYSL2->VTOT, "@E 999,999,999,999.99"), oFont10,385/*largura*/,50/*altura*/,,1,0)

		nLin+=50

		nTotLit += QRYSL2->VQTD
		nTotVal += QRYSL2->VTOT

		QRYSL2->(DbSkip())
	EndDo

	QRYSL2->(DbCloseArea()) // fecha a área criada

	If nLin > 2850
		fRodape()
		NovaPagina(nTipo)
	EndIf

	oPrint:Box(nLin,145,nLin+50,1630)
	oPrint:SayAlign(nLin+10, 155, "Total", oFont10N,510/*largura*/,50/*altura*/,,0,0)
	oPrint:SayAlign(nLin+10, 830, Transform(nTotLit, "@E 999,999,999,999.99"), oFont10N,385/*largura*/,50/*altura*/,,1,0)
	oPrint:SayAlign(nLin+10, 1235, Transform(nTotVal, "@E 999,999,999,999.99"), oFont10N,385/*largura*/,50/*altura*/,,1,0)
	nLin+=100
	nTotLit := 0
	nTotVal := 0

	fRodape()

	//// tela de impressão do relatório
	//DEFINE MSDIALOG oDlgImp TITLE "Tela de Impressão" FROM 0,0 TO 200,270 PIXEL
	//DEFINE FONT oBold NAME "Arial" SIZE 0, -13 BOLD
	//@ 000, 000 BITMAP oBmp RESNAME "LOGIN" oF oDlgImp SIZE 30, 120 NOBORDER WHEN .F. PIXEL
	//@ 003, 040 SAY "Relatório de Vendas Online" FONT oBold PIXEL
	//@ 014, 030 TO 16 ,400 LABEL '' OF oDlgImp  PIXEL
	//@ 030, 040 BUTTON "Configurar" 	SIZE 40,13 PIXEL OF oDlgImp ACTION oPrint:Setup()
	//@ 030, 090 BUTTON "Imprimir"   	SIZE 40,13 PIXEL OF oDlgImp ACTION oPrint:Print()
	//@ 050, 040 BUTTON "Visualizar"  SIZE 40,13 PIXEL OF oDlgImp ACTION oPrint:Preview()
	//@ 080, 090 BUTTON "Sair"       SIZE 40,13 PIXEL OF oDlgImp ACTION oDlgImp:End()
	//ACTIVATE MSDIALOG oDlgImp CENTER

	oPrint:Preview() //Visualiza antes de imprimir

    FreeObj(oPrint)
    oPrint := Nil

Return()

/*/{Protheus.doc} NovaPagina
Função que cria uma nova página

@type function
@version 12.1.33
@author Pablo Nunes
@since 04/04/2022
/*/
Static Function NovaPagina(nTipo)  // função que cria uma nova página montando o cabeçalho

	oPrint:endPage()
	nLin := 50
	nPagina += 1
	fCabecalho()
	If nTipo == 1 .or. nTipo == 2
		fCabecAbast(nTipo)
	Else
		fCabecProd()
	EndIf

Return()

//--------------------------------------------------
//Ajuste STATUS de abastecimentos da tabela (MID)
//--------------------------------------------------
Static Function AjuStatusMID()

	Local cSqlUpd := ""
	Local nStatus := 0
	Local dDatAte := iif(MV_PAR02<Date(),MV_PAR02,Date()-1)

	//ABASTECIMENTOS "BAIXADOS", POREM SEM NOTA FISCAL (SL2)
	cSqlUpd := "update MID set " + CRLF
	cSqlUpd += " MID.MID_NUMORC = 'P' " + CRLF
	cSqlUpd += " from "+RetSqlName("MID")+" MID " + CRLF
	cSqlUpd += " where MID.D_E_L_E_T_ = ' ' " + CRLF
	cSqlUpd += " and not exists ( "
	cSqlUpd += " select 1 "
	cSqlUpd += " from "+RetSqlName("SL2")+" SL2 "
	cSqlUpd += " where SL2.D_E_L_E_T_ = ' ' "
	cSqlUpd += " and MID.MID_FILIAL = SL2.L2_FILIAL "
	cSqlUpd += " and MID.MID_CODABA = SL2.L2_MIDCOD) " + CRLF
	cSqlUpd += " and MID.MID_FILIAL = '"+xFilial("MID")+"' " + CRLF
	cSqlUpd += " and MID.MID_DATACO >= '"+DTOS(MV_PAR01)+"' and MID.MID_DATACO <= '"+DTOS(dDatAte)+"' " + CRLF
	cSqlUpd += " and MID.MID_XPROD >= '"+MV_PAR03+"' and MID.MID_XPROD <= '"+MV_PAR04+"' " + CRLF
	cSqlUpd += " and MID.MID_NUMORC <> 'O     ' and MID.MID_NUMORC <> 'P     '" + CRLF //ABASTECIMENTOS COM "NUM" PREENCHIDO (BAIXADOS)
	cSqlUpd += " and MID.MID_AFERIR <> 'S'" + CRLF //DESCONSIDERO AFERIÇÕES

	//nStatus := TCSQLEXEC(cSqlUpd)

	//If (nStatus < 0)
	//	If !IsBlind()
	//		Alert("TCSQLError() " + TCSQLError())
	//	Else
	//		conout("TCSQLError() " + TCSQLError())
	//	EndIf
	//EndIf

//ABASTECIMENTOS "PENDENTES", POREM COM NOTA FISCAL (SL2)
	cSqlUpd := "update MID set " + CRLF
	cSqlUpd += " MID.MID_NUMORC = L2.L2_NUM " + CRLF
	cSqlUpd += " from "+RetSqlName("MID")+" MID " + CRLF
	cSqlUpd += " inner join "+RetSqlName("SL2")+" L2 on (L2.D_E_L_E_T_ = ' ' and MID.MID_FILIAL = L2.L2_FILIAL and MID.MID_CODABA = L2.L2_MIDCOD) " + CRLF
	cSqlUpd += " where MID.D_E_L_E_T_ = ' ' " + CRLF
	cSqlUpd += " and MID.MID_FILIAL = '"+xFilial("MID")+"' " + CRLF
	cSqlUpd += " and MID.MID_DATACO >= '"+DTOS(MV_PAR01)+"' and MID.MID_DATACO <= '"+DTOS(dDatAte)+"' " + CRLF
	cSqlUpd += " and MID.MID_XPROD >= '"+MV_PAR03+"' and MID.MID_XPROD <= '"+MV_PAR04+"' " + CRLF
	cSqlUpd += " and (MID.MID_NUMORC = 'P     ' or MID.MID_NUMORC = 'O     ')" + CRLF //ABASTECIMENTOS "PENDENTES"
	cSqlUpd += " and MID.MID_AFERIR <> 'S' " + CRLF //DESCONSIDERO AFERIÇÕES

	nStatus := TCSQLEXEC(cSqlUpd)

	If (nStatus < 0)
		If !IsBlind()
			Alert("TCSQLError() " + TCSQLError())
		Else
			conout("TCSQLError() " + TCSQLError())
		EndIf
	EndIf

Return
