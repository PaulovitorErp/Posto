#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"
#include "fwprintsetup.ch"

#define DMPAPER_A4 9 // A4 210 x 297 mm
#define IMP_PDF 6 // PDF

/*/{Protheus.doc} TRETR019
Geração de relatório de aferições com as listagem das aferições (tabela MID).

@type function
@version 12.1.33
@author Pablo Nunes
@since 17/02/2022
/*/
User Function TRETR019()

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
	Private oFont12	    := TFONT():New('Arial',,12,,.F.,,,,.F.,.F.	) //Fonte 12 Normal
	Private oFont12N	:= TFONT():New('Arial',,12,,.T.,,,,.F.,.F.	) //Fonte 12 Negrito
	Private oFont14N	:= TFONT():New('Times New Roman',,16,,.T.,,,,.F.,.F.	) //Fonte 14 Negrito
	Private oFont14NI	:= TFONT():New('Times New Roman',,14,,.T.,,,,.F.,.F.,.T.) //Fonte 14 Negrito e Itálico
	Private oFont16N	:= TFONT():New('Arial',,16,,.T.,,,,.F.,.F.	) //Fonte 16 Negrito
	Private oFont16NI	:= TFONT():New('Times New Roman',,16,,.T.,,,,.F.,.F.,.T.) //Fonte 16 Negrito e Itálico

////////////////////////////////////////////////////////////////////////////////////////////
	Private cStartPath
	Private nLin 		:= 50
	Private cArquivo	:= "TRETR019_"+DTOS(Date())+SUBSTR(Time(),1,2)+SUBSTR(Time(),4,2)+SUBSTR(Time(),7,2)
	Private oPrint
	Private oBrush		:= TBrush():New(,CLR_HGRAY )
	Private nPagina		:= 1

	Private cPerg		:= "TRETR019"
	Private oDlg

	If !fValidPerg()
		Return
	Endif

	if MV_PAR05 == 1
		
		oPrint := FwMSPrinter():New(cArquivo,IMP_PDF,.T.,,.T.,,,,.T.,.F.)
		oPrint:SetResolution(72)
		oPrint:SetPortrait() // ou SetLandscape()
		oPrint:SetPaperSize(DMPAPER_A4)
		oPrint:SetDevice(IMP_PDF)
		
		oPrint:Setup()

		If oPrint:nModalResult != PD_OK
			oPrint := Nil
			Return
		endif

		Processa({|| fCorpoRel() })
	else

		oPrint:= ReportDef()
		oPrint:PrintDialog()

	endif

Return()

/*/{Protheus.doc} fValidPerg
Perguntas SX1

@type function
@version 12.1.33
@author Pablo Nunes
@since 17/02/2022
/*/
Static Function fValidPerg()

	Local aHelpPor := {}

	U_uAjusSx1(cPerg,"01",OemToAnsi("Período de  ?"),"","","mv_ch1","D",10,0,0,"G","","","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"02",OemToAnsi("Período até ?"),"","","mv_ch2","D",10,0,0,"G","","","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"03",OemToAnsi("Produto de  ?"),"","","mv_ch3","C",tamsx3("B1_COD")[1],0,0,"G","","SB1","","","mv_par03","","","",space(tamsx3("B1_COD")[1]),"","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"04",OemToAnsi("Produto até ?"),"","","mv_ch4","C",tamsx3("B1_COD")[1] ,0,0,"G","","SB1","","","mv_par04","","","",replicate("Z",tamsx3("B1_COD")[1]),"","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"05","Modelo Impressão?","Modelo Impressão?","Modelo Impressão?","mv_ch5","N",1,0,0,"C","","","","",;
						"mv_par05","Gráfico (PDF)","","","","Texto (Excel)","","","","","","","","","","","",aHelpPor,{},{})

Return Pergunte(cPerg,.T.)

/*/{Protheus.doc} ReportDef
Definição do Relatorio
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ReportDef()

	Local oReport

	Local oSection1, oSection2

	Local cTitle    := "Relatório de Aferição por Período e PDV"

	oReport:= TReport():New(cPerg,cTitle,cPerg,{|oReport| fCorpoRel(oReport)},"Aferição por Período e PDV.")
	oReport:SetPortrait()
	oReport:HideParamPage()
	oReport:SetUseGC(.F.) //Desabilita o botão <Gestao Corporativa> do relatório


	oSection1 := TRSection():New(oReport,"Produto",{"QRYMID"})
	oSection1:SetHeaderPage(.T.)
	oSection1:SetHeaderSection(.T.)

	TRCell():New(oSection1,"MID_XPROD")
	TRCell():New(oSection1,"B1_DESC")

	oSection2 := TRSection():New(oSection1,"Aferições Realizadas",{"QRYMID"})
	oSection2:SetHeaderPage(.F.)
	oSection2:SetHeaderSection(.T.)
	oSection2:nLeftMargin := 3 

	TRCell():New(oSection2,"MID_CODBIC"	)
	TRCell():New(oSection2,"MID_ENCINI"	)
	TRCell():New(oSection2,"MID_ENCFIN"	)
	TRCell():New(oSection2,"MID_HORACO"	)
	TRCell():New(oSection2,"MID_LITABA"	)
	TRCell():New(oSection2,"MID_DATACO"	)
	TRCell():New(oSection2,"MID_PDV"	)
	TRCell():New(oSection2,"A3_NOME"	)

Return(oReport)


/*/{Protheus.doc} fCabecalho
Função que imprime o cabaçalho do relatório

@type function
@version 12.1.33
@author Pablo Nunes
@since 17/02/2022
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
	oPrint:Say(nLin+70, 390, "Aferição por Período e PDV", oFont10N)
	oPrint:Say(nLin+110, 390, "Período: "+DtoC(MV_PAR01)+" à "+DtoC(MV_PAR02), oFont10N)

	//Numero da página e data e hora
	oPrint:Box(nLin,1850,nLin+132,2300)
	oPrint:SayAlign(nLin+25, 1850, "Página: " + strzero(nPagina,3), oFont9N,450/*largura*/,50/*altura*/,,2,0)
	oPrint:SayAlign(nLin+65, 1850, DTOC(Date())+" "+Time(), oFont9N,450/*largura*/,50/*altura*/,,2,0)

	nLin+=132

	oPrint:Box(nLin,145,nLin+50,280)
	oPrint:SayAlign(nLin+10, 155, "Bico", oFont10N,115/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,280,nLin+50,550)
	oPrint:SayAlign(nLin+10, 290, "Encerrante Inicial", oFont10N,250/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,550,nLin+50,820)
	oPrint:SayAlign(nLin+10, 560, "Encerrante Final", oFont10N,250/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,820,nLin+50,955)
	oPrint:SayAlign(nLin+10, 830, "Hora", oFont10N,115/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,955,nLin+50,1225)
	oPrint:SayAlign(nLin+10, 965, "Qtd. Aferição", oFont10N,250/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,1225,nLin+50,1380)
	oPrint:SayAlign(nLin+10, 1235, "Data", oFont10N,135/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,1380,nLin+50,1600)
	oPrint:SayAlign(nLin+10, 1390, "PDV", oFont10N,200/*largura*/,50/*altura*/,,2,0)

	oPrint:Box(nLin,1600,nLin+50,2300)
	oPrint:SayAlign(nLin+10, 1610, "Operador", oFont10N,680/*largura*/,50/*altura*/,,2,0)

	nLin+=50

Return()

/*/{Protheus.doc} fRodape
Função para crair o rodapé do relatório

@type function
@version 12.1.33
@author Pablo Nunes
@since 17/02/2022
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
@since 17/02/2022
/*/
Static Function fCorpoRel(oReport)

	Local cQuery   	 := ""
	Local cProduto   := ""
	Local nTotal	 := 0
	Local nToGer     := 0
    Local aSM0       := {}
	Local oSection1		:= iif(oReport<>Nil,oReport:Section(1),Nil)
	Local oSection2		:= iif(oReport<>Nil,oReport:Section(1):Section(1),Nil)

    Private cNomeCom := ""

    DbSelectArea("MID")
    
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

	If Select("QRYMID") > 0
		QRYMID->(DbCloseArea())
	Endif

	cQuery += "SELECT MID.*, SB1.B1_DESC, " + CRLF
	If MID->(FieldPos( "MID_XOPERA" )) > 0
		cQuery += "SA3.A3_NOME " + CRLF
	Else
		cQuery += "'' AS A3_NOME " + CRLF
	EndIf
	cQuery += " FROM "+RetSqlName("MID")+" MID " + CRLF
	If MID->(FieldPos( "MID_XOPERA" )) > 0
		cQuery += " LEFT JOIN "+RetSqlName("SA3")+" SA3 ON (SA3.D_E_L_E_T_ = ' ' AND SA3.A3_FILIAL = '"+xFilial("SA3")+"' AND SA3.A3_COD = MID.MID_XOPERA) " + CRLF
	EndIf
	cQuery += " LEFT JOIN "+RetSqlName("SB1")+" SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_COD = MID.MID_XPROD) " + CRLF
	cQuery += " WHERE MID.D_E_L_E_T_ = ' ' "  + CRLF
	cQuery += " AND MID.MID_FILIAL	= '"+xFilial("MID")+"' " + CRLF
	cQuery += " AND MID.MID_DATACO	>= '"+DTOS(MV_PAR01)+"' AND MID.MID_DATACO<= '"+DTOS(MV_PAR02)+"' " + CRLF
	cQuery += " AND MID.MID_XPROD   >= '"+MV_PAR03+"' AND MID.MID_XPROD <= '"+MV_PAR04+"' " + CRLF
	cQuery += " AND MID.MID_AFERIR	= 'S' "  + CRLF //Aferição
	cQuery += " ORDER BY MID.MID_FILIAL, MID.MID_XPROD, MID.MID_DATACO" + CRLF

	cQuery := ChangeQuery(cQuery)
	TcQuery cQuery New Alias "QRYMID" // Cria uma nova area com o resultado do query

	if oReport <> NIL
		//oReport:SkipLine()
		//oReport:ThinLine()
		oReport:PrintText("Período: "+DtoC(MV_PAR01)+" à "+DtoC(MV_PAR02))
		oReport:SkipLine()

		oSection1:Init()
	else
		fCabecalho()
	endif

	While QRYMID->(!EOF())

		If nLin > 2850 .AND. oReport == NIL

			fRodape()
			NovaPagina()

			oPrint:Box(nLin,145,nLin+50,2300)
			oPrint:SayAlign(nLin+10, 155, AllTrim(QRYMID->MID_XPROD)+" - "+QRYMID->B1_DESC, oFont10N,2135/*largura*/,50/*altura*/,,0,0)
			nLin+=50

		EndIf

		If cProduto <> AllTrim(QRYMID->MID_XPROD)
			If !Empty(cProduto)
				if oReport <> NIL
					oReport:PrintText("    TOTAL LITROS DO COMBUSTÍVEL: "+ Transform(nTotal, "@E 999,999,999,999.99"))
					oReport:SkipLine()
					oReport:ThinLine()
					oSection2:Finish()
				else
					oPrint:Box(nLin,145,nLin+50,2300)
					oPrint:SayAlign(nLin+10, 155, "Total do Combustível", oFont10N,1360-155/*largura*/,50/*altura*/,,0,0)
					oPrint:SayAlign(nLin+10, 1360, Transform(nTotal, "@E 999,999,999,999.99"), oFont10N,2290-1360/*largura*/,50/*altura*/,,1,0)
					nLin+=50
				endif
				nTotal := 0
			EndIf

			cProduto := AllTrim(QRYMID->MID_XPROD)

			if oReport <> NIL

				oSection1:Cell("MID_XPROD"):SetValue(QRYMID->MID_XPROD)
				oSection1:Cell("B1_DESC"):SetValue(QRYMID->B1_DESC)
				oSection1:PrintLine()

				oSection2:Init()
			else
				oPrint:Box(nLin,145,nLin+50,2300)
				oPrint:SayAlign(nLin+10, 155, AllTrim(QRYMID->MID_XPROD)+" - "+QRYMID->B1_DESC, oFont10N,2135/*largura*/,50/*altura*/,,0,0)
				nLin+=50
			endif
		EndIf

		If nLin > 2850 .AND. oReport == NIL

			fRodape()
			NovaPagina()

			oPrint:Box(nLin,145,nLin+50,2300)
			oPrint:SayAlign(nLin+10, 155, AllTrim(QRYMID->MID_XPROD)+" - "+QRYMID->B1_DESC, oFont10N,2135/*largura*/,50/*altura*/,,0,0)
			nLin+=50

		EndIf

		if oReport <> NIL

			oSection2:Cell("MID_CODBIC"):SetValue(QRYMID->MID_CODBIC)
			oSection2:Cell("MID_ENCINI"):SetValue(QRYMID->MID_ENCINI)
			oSection2:Cell("MID_ENCFIN"):SetValue(QRYMID->MID_ENCFIN)
			oSection2:Cell("MID_HORACO"):SetValue(QRYMID->MID_HORACO)
			oSection2:Cell("MID_LITABA"):SetValue(QRYMID->MID_LITABA)
			oSection2:Cell("MID_DATACO"):SetValue(QRYMID->MID_DATACO)
			oSection2:Cell("MID_PDV"):SetValue(QRYMID->MID_PDV)
			oSection2:Cell("A3_NOME"):SetValue(QRYMID->A3_NOME)
			oSection2:PrintLine()

		else
			
			oPrint:Box(nLin,145,nLin+50,280)
			oPrint:SayAlign(nLin+10, 155, QRYMID->MID_CODBIC, oFont10,115/*largura*/,50/*altura*/,,2,0)

			oPrint:Box(nLin,280,nLin+50,550)
			oPrint:SayAlign(nLin+10, 290, Transform(QRYMID->MID_ENCINI , "@E 999,999,999,999.99"), oFont10,250/*largura*/,50/*altura*/,,1,0) //QRYMID->MID_ENCFIN-QRYMID->MID_LITABA

			oPrint:Box(nLin,550,nLin+50,820)
			oPrint:SayAlign(nLin+10, 560, Transform(QRYMID->MID_ENCFIN, "@E 999,999,999,999.99"), oFont10,250/*largura*/,50/*altura*/,,1,0)

			oPrint:Box(nLin,820,nLin+50,955)
			oPrint:SayAlign(nLin+10, 830, QRYMID->MID_HORACO, oFont10,115/*largura*/,50/*altura*/,,2,0)

			oPrint:Box(nLin,955,nLin+50,1225)
			oPrint:SayAlign(nLin+10, 965, Transform(QRYMID->MID_LITABA, "@E 999,999,999,999.99"), oFont10,250/*largura*/,50/*altura*/,,1,0)

			oPrint:Box(nLin,1225,nLin+50,1380)
			oPrint:SayAlign(nLin+10, 1235, DtoC(StoD(QRYMID->MID_DATACO)), oFont10,135/*largura*/,50/*altura*/,,2,0)

			oPrint:Box(nLin,1380,nLin+50,1600)
			oPrint:SayAlign(nLin+10, 1390, QRYMID->MID_PDV, oFont10,200/*largura*/,50/*altura*/,,0,0)

			oPrint:Box(nLin,1600,nLin+50,2300)
			oPrint:SayAlign(nLin+10, 1610, QRYMID->A3_NOME, oFont10,680/*largura*/,50/*altura*/,,0,0)

			nLin+=50

		endif

		nTotal += QRYMID->MID_LITABA
		nToGer += QRYMID->MID_LITABA

		QRYMID->(DbSkip())

	EndDo
	
	if oReport <> NIL

		oReport:PrintText("    TOTAL LITROS DO COMBUSTÍVEL: "+ Transform(nTotal, "@E 999,999,999,999.99"))
		oReport:SkipLine()
		oReport:ThinLine()

		oReport:PrintText("    TOTAL LITROS GERAL: "+ Transform(nToGer, "@E 999,999,999,999.99"))
		
		oSection2:Finish()
		oSection1:Finish()

	else
		oPrint:Box(nLin,145,nLin+50,2300)
		oPrint:SayAlign(nLin+10, 155, "Total do Combustível", oFont10N,1360-155/*largura*/,50/*altura*/,,0,0)
		oPrint:SayAlign(nLin+10, 1360, Transform(nTotal, "@E 999,999,999,999.99"), oFont10N,2290-1360/*largura*/,50/*altura*/,,1,0)
		nLin+=50
		oPrint:Box(nLin,145,nLin+50,2300)
		oPrint:SayAlign(nLin+10, 155, "Total Geral", oFont10N,1360-155/*largura*/,50/*altura*/,,0,0)
		oPrint:SayAlign(nLin+10, 1360, Transform(nToGer, "@E 999,999,999,999.99"), oFont10N,2290-1360/*largura*/,50/*altura*/,,1,0)
		nLin+=50

		fRodape()

		oPrint:Print()
	endif

	QRYMID->(DbCloseArea()) // fecha a área criada

Return()

/*/{Protheus.doc} NovaPagina
Função que cria uma nova página

@type function
@version 12.1.33
@author Pablo Nunes
@since 17/02/2022
/*/
Static Function NovaPagina()  // função que cria uma nova página montando o cabeçalho

	oPrint:endPage()
	nLin := 50
	nPagina += 1
	fCabecalho()

Return()

