#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} RPOS006
Imprime Termo de Abertura e de Encerramento para o LMC (Livro de Movimentacao de Combustivel).
@author Maiki Perin
@since 03/11/2018
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User Function TRETR004()

	Private oFont6			:= TFont():New("Arial",,6,.T.,.F.,5,.T.,5,.T.,.F.) 			//Fonte 6 Normal
	Private oFont6N 		:= TFont():New("Arial",,6,,.T.,,,,.T.,.F.) 					//Fonte 6 Negrito
	Private oFont8			:= TFont():New('Arial',,8,,.F.,,,,.F.,.F.) 					//Fonte 8 Normal
	Private oFont8N			:= TFont():New('Arial',,8,,.T.,,,,.F.,.F.) 				 	//Fonte 8 Negrito
	Private oFont8NI		:= TFont():New('Times New Roman',,8,,.T.,,,,.F.,.F.,.T.) 	//Fonte 8 Negrito e Itálico
	Private oFont10			:= TFont():New('Arial',,10,,.F.,,,,.F.,.F.) 				//Fonte 10 Normal
	Private oFont10N		:= TFont():New('Arial',,10,,.T.,,,,.F.,.F.) 				//Fonte 10 Negrito
	Private oFont12			:= TFont():New('Arial',,12,,.F.,,,,.F.,.F.) 				//Fonte 12 Normal
	Private oFont12N		:= TFont():New('Arial',,12,,.T.,,,,.F.,.F.) 			 	//Fonte 12 Negrito
	Private oFont14			:= TFont():New('Arial',,14,,.F.,,,,.F.,.F.) 				//Fonte 14 Normal
	Private oFont13N		:= TFont():New('Arial',,13,,.T.,,,,.F.,.F.) 				//Fonte 13 Negrito
	Private oFont14N		:= TFont():New('Arial',,14,,.T.,,,,.F.,.F.) 				//Fonte 14 Negrito
	Private oFont14NI		:= TFont():New('Times New Roman',,14,,.T.,,,,.F.,.F.,.T.) 	//Fonte 14 Negrito e Itálico
	Private oFont16N		:= TFont():New('Arial',,16,,.T.,,,,.F.,.F.) 				//Fonte 16 Negrito
	Private oFont16NI		:= TFont():New('Times New Roman',,16,,.T.,,,,.F.,.F.,.T.) 	//Fonte 16 Negrito e Itálico
	Private oFont18			:= TFont():New("Arial",,18,,.F.,,,,,.F.,.F.)				//Fonte 18 Negrito
	Private oFont18N		:= TFont():New("Arial",,18,,.T.,,,,,.F.,.F.)				//Fonte 18 Negrito
	Private oFont22			:= TFont():New("Arial",,22,,.F.,,,,,.F.,.F.)				//Fonte 26 Normal

	Private oBrush			:= TBrush():New(,CLR_HGRAY)

	Private cPerg			:= "TRETR004"

	Private nLin 			:= 80
	Private oRel			:= TmsPrinter():New("")

	Private cTpSeq			:= ""
	Private nNroDias		:= 0

	If !ValidPerg()
		Return
	Endif

	While Empty(MV_PAR01)

		MsgInfo("O parâmetro <Nro. Livro> é obrigatório!!","Atenção")

		If !ValidPerg()
			Return
		Endif
	EndDo

	oRel:setPaperSize(DMPAPER_A4)

	oRel:SetPortrait()///Define a orientacao da impressao como retrato
	//oRel:SetLandscape() ///Define a orientacao da impressao como paisagem
	//oRel:Setup()

	DbSelectArea("UB4")
	UB4->(dbSetOrder(3)) //UB4_FILIAL+UB4_PROD+UB4_NUMERO

	If UB4->(DbSeek(xFilial("UB4")+MV_PAR01+MV_PAR02))
		cTpSeq := UB4->UB4_PAGINA
		ImpAbr()
		ImpEnc()
	Else
		MsgInfo("Parâmetros (Produto e Nro. Livro) inválidos!!","Atenção")
		Return
	Endif

	oRel:Preview()

Return

/*/{Protheus.doc} ImpAbr
Impressao Abertura
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ImpAbr()

	Local cDist 	:= ""
	Local aMes  	:= Array(12)
	Local cOrgao    := SuperGetMv("MV_XLMCORG",,"")
	Local aEnd		:= {}

	Local cM0_NOMECOM := ""
	Local cM0_ENDENT  := ""
	Local cM0_COMPENT := ""
	Local cM0_CIDENT  := ""
	Local cM0_ESTENT  := ""
	Local cM0_CGC     := ""
	Local cM0_INSC    := ""
	Local cM0_INSCM   := ""

	aMes[01] := "Janeiro"
	aMes[02] := "Fevereiro"
	aMes[03] := "Marco"
	aMes[04] := "Abril"
	aMes[05] := "Maio"
	aMes[06] := "Junho"
	aMes[07] := "Julho"
	aMes[08] := "Agosto"
	aMes[09] := "Setembro"
	aMes[10] := "Outubro"
	aMes[11] := "Novembro"
	aMes[12] := "Dezembro"

	If Findfunction("FindClass") .AND. FindClass("FWSM0Util")
		If Empty(Select("SM0"))
			OpenSM0(cEmpAnt)
		EndIf
		aSM0 := FWSM0Util():GetSM0Data()
		cM0_NOMECOM := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_NOMECOM"})][2]
		cM0_ENDENT  := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_ENDENT"})][2]
		cM0_COMPENT := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_COMPENT"})][2]
		cM0_CIDENT  := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_CIDENT"})][2]
		cM0_ESTENT  := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_ESTENT"})][2]
		cM0_CGC     := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_CGC"})][2]
		cM0_INSC    := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_INSC"})][2]
		cM0_INSCM   := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_INSCM"})][2]
	Else
		cM0_NOMECOM := SM0->M0_NOMECOM
		cM0_ENDENT  := SM0->M0_ENDENT
		cM0_COMPENT := SM0->M0_COMPENT
		cM0_CIDENT  := SM0->M0_CIDENT
		cM0_ESTENT  := SM0->M0_ESTENT
		cM0_CGC     := SM0->M0_CGC
		cM0_INSC    := SM0->M0_INSC
		cM0_INSCM   := SM0->M0_INSCM
	EndIf

	oRel:StartPage() //Inicia uma nova pagina

	oRel:Say(nLin + 015,0170,"Livro de Movimentação de Combustíveis (LMC) FOLHA: 001",oFont22)
	oRel:Say(nLin + 130,0870,"Portaria Nº 26, de 13 de novembro de 1992",oFont12)
	oRel:Say(nLin + 240,0980,Posicione("SB1",1,xFilial("SB1")+UB4->UB4_PROD,"B1_DESC"),oFont18)
	oRel:Say(nLin + 410,1070,"Nº do Livro: " + AllTrim(UB4->UB4_NUMERO),oFont12)

	nLin := 680

	oRel:Say(nLin + 050,0830,"TERMO DE ABERTURA",oFont22)
	If cTpSeq == "E" //Em Branco
		oRel:Say(nLin + 280,0260,"Contém este livro _____ ("+Space(20)+") folhas tipograficamente numeradas de nº 001 a _____ e serviu para",oFont12)
		oRel:Say(nLin + 330,0260,"o lançamento das operações do Estabelecimento do contribuinte abaixo identificado.",oFont12)
	ElseIf cTpSeq == "R" //Repetido
		nNroDias := 3
		oRel:Say(nLin + 280,0260,"Contém este livro "+AllTrim(StrZero(nNroDias,3))+" ("+AllTrim(Extenso(nNroDias,.T.))+") folhas tipograficamente numeradas de nº 001 a "+StrZero(nNroDias,3)+" e serviu para",oFont12)
		oRel:Say(nLin + 330,0260,"o lançamento das operações do Estabelecimento do contribuinte abaixo identificado.",oFont12)
	ElseIf cTpSeq == "S" //Sequencial
		nNroDias := RetPag(UB4->UB4_PROD,UB4->UB4_NUMERO) + 2
		oRel:Say(nLin + 280,0260,"Contém este livro "+AllTrim(StrZero(nNroDias,3))+" ("+AllTrim(Extenso(nNroDias,.T.))+") folhas tipograficamente numeradas de nº 001 a "+StrZero(nNroDias,3)+" e serviu para",oFont12)
		oRel:Say(nLin + 330,0260,"o lançamento das operações do Estabelecimento do contribuinte abaixo identificado.",oFont12)
	Endif
	oRel:Say(nLin + 500,0540,"Livro de Movimentação de Combustíveis",oFont22)
	oRel:Say(nLin + 600,1150,"(LMC)",oFont22)

	nLin := 1530

	oRel:Say(nLin + 000,0300,"Da Firma:",oFont12)
	oRel:Say(nLin + 000,1200,AllTrim(cM0_NOMECOM),oFont12)

	oRel:Say(nLin + 080,0300,"Estabelecida à:",oFont12)
	aEnd := U_UQuebTxt(AllTrim(cM0_ENDENT) + Space(1) + AllTrim(cM0_COMPENT),40)
	oRel:Say(nLin + 080,1200,aEnd[1],oFont12)
	If Len(aEnd) > 1
		nLin += 50
		oRel:Say(nLin + 080,1200,aEnd[2],oFont12)
	Endif

	oRel:Say(nLin + 160,0300,"Na cidade de:",oFont12)
	oRel:Say(nLin + 160,1200,AllTrim(cM0_CIDENT),oFont12)

	oRel:Say(nLin + 240,0300,"Estado de:",oFont12)
	oRel:Say(nLin + 240,1200,AllTrim(cM0_ESTENT),oFont12)

	oRel:Say(nLin + 320,0300,"CNPJ:",oFont12)
	oRel:Say(nLin + 320,1200,Transform(AllTrim(cM0_CGC),"@R 99.999.999/9999-99"),oFont12)

	//If cFilAnt == "0301" //Frutal
	//	oRel:Say(nLin + 400,0300,"JUCEMG:",oFont12)
	//Endif
	oRel:Say(nLin + 400,1200,AllTrim(cOrgao),oFont12)

	oRel:Say(nLin + 480,0300,"Inscrição Estadual:",oFont12)
	oRel:Say(nLin + 480,1200,AllTrim(cM0_INSC),oFont12)

	oRel:Say(nLin + 560,0300,"Inscrição Municipal:",oFont12)
	oRel:Say(nLin + 560,1200,AllTrim(cM0_INSCM),oFont12)

	//Distribuidora
	//cDist := Posicione("SX5",1,xFilial("SX5")+"IN"+MV_PAR03,"X5_DESCRI")
	cDist := Posicione("SA2",1,xFilial("SA2")+MV_PAR03,"A2_NOME")
	oRel:Say(nLin + 640,0300,"Distribuidora:", oFont12)
	oRel:Say(nLin + 640,1200,cDist, oFont12)

	oRel:Say(nLin + 720,0300,"Capacidade Nominal de Armazenamento:",oFont12)

	DbSelectArea("MHZ")
	MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL

	If MHZ->(DbSeek(xFilial("MHZ")+UB4->UB4_PROD))
		While MHZ->(!EOF()) .And. MHZ->MHZ_FILIAL == xFilial("MHZ") .And. MHZ->MHZ_CODPRO == UB4->UB4_PROD
			if ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dDataBase) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dDataBase))
				oRel:Say(nLin + 720,1200,Transform(MHZ->MHZ_CAPNOM,"@E 999,999"),oFont12)
				nLin += 50
			endif
			MHZ->(DbSkip())
		EndDo
	Endif

	nLin := 2850

	nMes := Val(Substr(UB4->UB4_COMPET,1,2))
	oRel:Say(nLin,0317,AllTrim(cM0_CIDENT) + ", " + "01" + " de " + aMes[nMes] + " de " + "20" + SubStr(UB4->UB4_COMPET,5,2),oFont12)
	oRel:Say(nLin + 050,0480,"Data de Abertura",oFont12)

	oRel:Say(nLin + 400,0700,"______________________________________________",oFont12)
	oRel:Say(nLin + 450,0800,"Assinatura do Representante Legal da Empresa",oFont12)

	oRel:EndPage()

Return

/*/{Protheus.doc} ImpEnc
Impressao Encerramento
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ImpEnc()

	Local cDist 	:= ""

	Local dPriDia 	:= SToD(SubStr(UB4->UB4_COMPET,3,4) + SubStr(UB4->UB4_COMPET,1,2) + "01")
	Local dUltDia	:= LastDay(dPriDia)

	Local aMes  	:= Array(12)
	Local cOrgao    := SuperGetMv("MV_XLMCORG",,"")
	Local aEnd		:= {}

	Local cM0_NOMECOM := ""
	Local cM0_ENDENT  := ""
	Local cM0_COMPENT := ""
	Local cM0_CIDENT  := ""
	Local cM0_ESTENT  := ""
	Local cM0_CGC     := ""
	Local cM0_INSC    := ""
	Local cM0_INSCM   := ""

	If Findfunction("FindClass") .AND. FindClass("FWSM0Util")
		If Empty(Select("SM0"))
			OpenSM0(cEmpAnt)
		EndIf
		aSM0 := FWSM0Util():GetSM0Data()
		cM0_NOMECOM := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_NOMECOM"})][2]
		cM0_ENDENT  := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_ENDENT"})][2]
		cM0_COMPENT := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_COMPENT"})][2]
		cM0_CIDENT  := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_CIDENT"})][2]
		cM0_ESTENT  := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_ESTENT"})][2]
		cM0_CGC     := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_CGC"})][2]
		cM0_INSC    := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_INSC"})][2]
		cM0_INSCM   := aSM0[aScan(aSM0,{|x| alltrim(x[1])=="M0_INSCM"})][2]
	Else
		cM0_NOMECOM := SM0->M0_NOMECOM
		cM0_ENDENT  := SM0->M0_ENDENT
		cM0_COMPENT := SM0->M0_COMPENT
		cM0_CIDENT  := SM0->M0_CIDENT
		cM0_ESTENT  := SM0->M0_ESTENT
		cM0_CGC     := SM0->M0_CGC
		cM0_INSC    := SM0->M0_INSC
		cM0_INSCM   := SM0->M0_INSCM
	EndIf

	aMes[01] := "Janeiro"
	aMes[02] := "Fevereiro"
	aMes[03] := "Marco"
	aMes[04] := "Abril"
	aMes[05] := "Maio"
	aMes[06] := "Junho"
	aMes[07] := "Julho"
	aMes[08] := "Agosto"
	aMes[09] := "Setembro"
	aMes[10] := "Outubro"
	aMes[11] := "Novembro"
	aMes[12] := "Dezembro"

	oRel:StartPage() //Inicia uma nova pagina

	nLin := 80

	oRel:Say(nLin + 015,0170,"Livro de Movimentação de Combustíveis (LMC) FOLHA: " + iif(cTpSeq == "E","_________",StrZero(nNroDias,3)),oFont22)
	oRel:Say(nLin + 130,0870,"Portaria Nº 26, de 13 de novembro de 1992",oFont12)
	oRel:Say(nLin + 240,0980,Posicione("SB1",1,xFilial("SB1")+UB4->UB4_PROD,"B1_DESC"),oFont18)
	oRel:Say(nLin + 410,1070,"Nº do Livro: " + AllTrim(UB4->UB4_NUMERO),oFont12)

	nLin := 680

	oRel:Say(nLin + 050,0750,"TERMO DE ENCERRAMENTO",oFont22)
	If cTpSeq == "E" //Em Branco
		oRel:Say(nLin + 280,0260,"Contém este livro _____ ("+Space(20)+") folhas tipograficamente numeradas de nº 001 a _____ e serviu para",oFont12)
		oRel:Say(nLin + 330,0260,"o lançamento das operações do Estabelecimento do contribuinte abaixo identificado.",oFont12)
	ElseIf cTpSeq == "R" //Repetido
		oRel:Say(nLin + 280,0260,"Contém este livro "+AllTrim(StrZero(nNroDias,3))+" ("+AllTrim(Extenso(nNroDias,.T.))+") folhas tipograficamente numeradas de nº 001 a "+StrZero(nNroDias,3)+" e serviu para",oFont12)
		oRel:Say(nLin + 330,0260,"o lançamento das operações do Estabelecimento do contribuinte abaixo identificado.",oFont12)
	ElseIf cTpSeq == "S" //Sequencial
		oRel:Say(nLin + 280,0260,"Contém este livro "+AllTrim(StrZero(nNroDias,3))+" ("+AllTrim(Extenso(nNroDias,.T.))+") folhas tipograficamente numeradas de nº 001 a "+StrZero(nNroDias,3)+" e serviu para",oFont12)
		oRel:Say(nLin + 330,0260,"o lançamento das operações do Estabelecimento do contribuinte abaixo identificado.",oFont12)
	Endif
	//oRel:Say(nLin + 280,0260,"Contém este livro "+AllTrim(StrZero(nNroDias,3))+" ("+AllTrim(Extenso(nNroDias,.T.))+") folhas tipograficamente numeradas de nº 001 a "+StrZero(nNroDias,3)+" e serviu para",oFont12)
	//oRel:Say(nLin + 330,0260,"o lançamento das operações do Estabelecimento do contribuinte abaixo identificado.",oFont12)
	oRel:Say(nLin + 500,0540,"Livro de Movimentação de Combustíveis",oFont22)
	oRel:Say(nLin + 600,1150,"(LMC)",oFont22)

	nLin := 1530

	oRel:Say(nLin + 000,0300,"Da Firma:",oFont12)
	oRel:Say(nLin + 000,1200,AllTrim(cM0_NOMECOM),oFont12)

	oRel:Say(nLin + 080,0300,"Estabelecida à:",oFont12)

	aEnd := U_UQuebTxt(AllTrim(cM0_ENDENT) + Space(1) + AllTrim(cM0_COMPENT),40)
	oRel:Say(nLin + 080,1200,aEnd[1],oFont12)
	If Len(aEnd) > 1
		nLin += 50
		oRel:Say(nLin + 080,1200,aEnd[2],oFont12)
	Endif

	oRel:Say(nLin + 160,0300,"Na cidade de:",oFont12)
	oRel:Say(nLin + 160,1200,AllTrim(cM0_CIDENT),oFont12)

	oRel:Say(nLin + 240,0300,"Estado de:",oFont12)
	oRel:Say(nLin + 240,1200,AllTrim(cM0_ESTENT),oFont12)

	oRel:Say(nLin + 320,0300,"CNPJ:",oFont12)
	oRel:Say(nLin + 320,1200,Transform(AllTrim(cM0_CGC),"@R 99.999.999/9999-99"),oFont12)

	//If cFilAnt == "0301" //Frutal
	//	oRel:Say(nLin + 400,0300,"JUCEMG:",oFont12)
	//Endif
	oRel:Say(nLin + 400,1200,AllTrim(cOrgao),oFont12)

	oRel:Say(nLin + 480,0300,"Inscrição Estadual:",oFont12)
	oRel:Say(nLin + 480,1200,AllTrim(cM0_INSC),oFont12)

	oRel:Say(nLin + 560,0300,"Inscrição Municipal:",oFont12)
	oRel:Say(nLin + 560,1200,AllTrim(cM0_INSCM),oFont12)

	//Distribuidora
	cDist := Posicione("SX5",1,xFilial("SX5")+"IN"+MV_PAR03,"X5_DESCRI")
	oRel:Say(nLin + 640,0300,"Distribuidora:", oFont12)
	oRel:Say(nLin + 640,1200,cDist, oFont12)

	oRel:Say(nLin + 720,0300,"Capacidade Nominal de Armazenamento:",oFont12)

	dbSelectArea("MHZ")
	MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL

	If MHZ->(DbSeek(xFilial("MHZ")+UB4->UB4_PROD))

		While MHZ->(!EOF()) .And. MHZ->MHZ_FILIAL == xFilial("MHZ") .And. MHZ->MHZ_CODPRO == UB4->UB4_PROD
			oRel:Say(nLin + 720,1200,Transform(MHZ->MHZ_CAPNOM,"@E 999,999"),oFont12)
			nLin += 50

			MHZ->(DbSkip())
		EndDo
	Endif

	nLin := 2850

	nMes := Val(Substr(UB4->UB4_COMPET,1,2))
	oRel:Say(nLin,0317,AllTrim(cM0_CIDENT) + ", " + SubStr(DToC(dUltDia),1,2) + " de " + aMes[nMes] + " de " + "20" + SubStr(UB4->UB4_COMPET,5,2),oFont12)
	oRel:Say(nLin + 050,0480,"Data de Encerramento",oFont12)

	oRel:Say(nLin + 400,0700,"______________________________________________",oFont12)
	oRel:Say(nLin + 450,0800,"Assinatura do Representante Legal da Empresa",oFont12)

	oRel:EndPage()

Return

/*/{Protheus.doc} ValidPerg
Perguntas SX1
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ValidPerg()

	Local aHelpPor := {}

	U_uAjusSx1(cPerg,"01",OemToAnsi("Produto            ?"),"","","mv_ch1","C",15,0,0,"G","","SB1","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"02",OemToAnsi("Nro. Livro         ?"),"","","mv_ch2","C",06,0,0,"G","","UB4","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor,{},{})
	U_uAjusSx1(cPerg,"03",OemToAnsi("Distribuidora      ?"),"","","mv_ch3","C",06,0,0,"G","","SA2","","","mv_par03","","","","","","","","","","","","","","","","",aHelpPor,{},{})

Return Pergunte(cPerg,.T.)

/*/{Protheus.doc} RetPag
Retornoa paginas
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param cProd, characters, descricao
@param cNroLivro, characters, descricao
@type function
/*/
Static Function RetPag(cProd,cNroLivro)

	Local nQtdPag	:= 0
	Local nQtdRec	:= 0
	Local nQtdVen	:= 0

	Local nPag		:= 0
	Local nAux		:= 0

	Local cQry		:= ""
	Local oLMC 

	If Select("QRYLMC") > 0
		QRYLMC->(DbCloseArea())
	Endif

	cQry := "SELECT DISTINCT MIE.MIE_DATA, MIE.MIE_CODPRO"
	cQry += " FROM "+RetSqlName("MIE")+" MIE, "+RetSqlName("UB4")+" UB4"
	cQry += " WHERE MIE.D_E_L_E_T_ 	<> '*'"
	cQry += " AND UB4.D_E_L_E_T_ 	<> '*'"
	cQry += " AND MIE.MIE_FILIAL 	= '"+xFilial("MIE")+"'"
	cQry += " AND UB4.UB4_FILIAL 	= '"+xFilial("UB4")+"'"
	cQry += " AND MIE.MIE_NRLIVR	= UB4.UB4_CODIGO"
	cQry += " AND MIE.MIE_CODPRO	= UB4.UB4_PROD"
	cQry += " AND UB4.UB4_PROD		= '"+cProd+"'"
	cQry += " AND UB4.UB4_NUMERO	= '"+cNroLivro+"'"
	cQry += " ORDER BY 1,2"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETR004.txt",cQry)
	TcQuery cQry NEW Alias "QRYLMC"

	While QRYLMC->(!EOF())

		nPag := 1

		nQtdRec := RetRec(QRYLMC->MIE_CODPRO,QRYLMC->MIE_DATA)

		If nQtdRec > 15
			If (nQtdRec / 15) - Int((nQtdRec / 15)) > 0
				nPag := Int(nQtdRec / 15) + 1
			Else
				nPag := nQtdRec / 15
			Endif
		Endif

		//retorna dados de vendas
		oLMC := TLmcLib():New(QRYLMC->MIE_CODPRO, STOD(QRYLMC->MIE_DATA) )
		oLMC:SetTRetVen(3) //1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros
		nQtdVen := oLMC:RetVen()

		If nQtdVen > 20

			If (nQtdVen / 20) - Int((nQtdVen / 20)) > 0
				nAux := Int(nQtdVen / 20) + 1
			Else
				nAux := nQtdVen / 20
			Endif

			If nAux > nPag
				nPag := nAux
			Endif
		Endif

		nQtdPag += nPag

		QRYLMC->(DbSkip())
	EndDo

	If Select("QRYTQ") > 0
		QRYTQ->(DbCloseArea())
	Endif

	If Select("QRYLMC") > 0
		QRYLMC->(DbCloseArea())
	Endif

Return nQtdPag

/*/{Protheus.doc} RetRec
Retorna Qtd
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param cProd, characters, descricao
@param dData, date, descricao
@type function
/*/
Static Function RetRec(cProd,dData)

	Local nQtdRec	:= 0

	Local cQry		:= ""

	If Select("QRYREC") > 0
		QRYREC->(dbCloseArea())
	Endif

	cQry := "SELECT SF1.F1_EMISSAO, SF1.F1_DOC, SA2.A2_NOME, SD1.D1_LOCAL, SUM(SD1.D1_QUANT) AS QTD, SF1.F1_TIPO, SF1.F1_FORNECE, SF1.F1_LOJA"

	cQry += " FROM "+RetSqlName("SF1")+" SF1 INNER JOIN "+RetSqlName("SD1")+" SD1 ON SF1.F1_DOC			= SD1.D1_DOC"
	cQry += " 																		AND SF1.F1_SERIE	= SD1.D1_SERIE"
	cQry += " 																		AND SF1.F1_FORNECE	= SD1.D1_FORNECE"
	cQry += " 																		AND SF1.F1_LOJA		= SD1.D1_LOJA"
	cQry += " 																		AND SD1.D1_COD		= '"+cProd+"'"
	cQry += " 																		AND SD1.D1_FILIAL	= '"+xFilial("SD1")+"'"
	cQry += " 																		AND SD1.D_E_L_E_T_ 	<> '*'"

	cQry += " 								LEFT JOIN "+RetSqlName("SA2")+" SA2 ON 	SF1.F1_FORNECE		= SA2.A2_COD"
	cQry += " 																		AND SF1.F1_LOJA		= SA2.A2_LOJA"
	cQry += " 																		AND SA2.D_E_L_E_T_ 	<> '*'"
	cQry += " 																		AND SA2.A2_FILIAL	= '"+xFilial("SA2")+"'"

	cQry += "								INNER JOIN "+RetSqlName("SF4")+" SF4 ON SD1.D1_TES			= SF4.F4_CODIGO"
	cQry += " 																		AND SF4.D_E_L_E_T_ 	<> '*'"
	cQry += " 																		AND SF4.F4_FILIAL	= '"+xFilial("SF4")+"'"
	cQry += " 																		AND SF4.F4_ESTOQUE	= 'S'" //Movimenta estoque

	cQry += " WHERE SF1.D_E_L_E_T_ 	<> '*'"
	cQry += " AND SF1.F1_FILIAL		= '"+xFilial("SF1")+"'"
	cQry += " AND SF1.F1_DTDIGIT	= '"+dData+"'"
	cQry += " GROUP BY SF1.F1_EMISSAO, SF1.F1_DOC, SA2.A2_NOME, SD1.D1_LOCAL, SF1.F1_TIPO, SF1.F1_FORNECE, SF1.F1_LOJA"
	cQry += " ORDER BY 1,2"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\RPOS011.txt",cQry)
	TcQuery cQry NEW Alias "QRYREC"

	While QRYREC->(!EOF())

		nQtdRec++

		QRYREC->(dbSkip())
	EndDo

	If Select("QRYREC") > 0
		QRYREC->(dbCloseArea())
	Endif

Return nQtdRec
