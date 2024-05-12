#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

#DEFINE TAMLINCABEC 55

/*/{Protheus.doc} TRETR007
Controle de Recebimento de Combustivel [CRC]
@author Totvs
@since 24/04/2014
@version 1.0
@return nulo
@type define
/*/
User Function TRETR007()

	Local cNumDe      	:= ""
	Local cNumAte     	:= ""
	Local cQry			:= ""
	Local cQry2			:= ""

	///////////////////////////////////////////////////////////////////////
	///Variaveis de fontes                                             ////
	///////////////////////////////////////////////////////////////////////
	Private oFont6		:= TFONT():New("ARIAL",7,6,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 6 Normal
	Private oFont6N 	:= TFONT():New("ARIAL",7,6,,.T.,,,,.T.,.F.) ///Fonte 6 Negrito
	Private oFont8		:= TFONT():New("ARIAL",9,8,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 8 Normal
	Private oFont8N 	:= TFONT():New("ARIAL",8,8,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
	Private oFont10 	:= TFONT():New("ARIAL",9,10,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 10 Normal
	Private oFont10S	:= TFONT():New("ARIAL",9,10,.T.,.F.,5,.T.,5,.T.,.T.) ///Fonte 10 Sublinhando
	Private oFont10N 	:= TFONT():New("ARIAL",9,10,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
	Private oFont11		:= TFONT():New("ARIAL",11,11,,.F.,,,,.T.,.F.) ///Fonte 11 Normal
	Private oFont11NS	:= TFONT():New("ARIAL",11,11,,.T.,,,,.T.,.T.) ///Fonte 11 Negrito e Sublinhado
	Private oFont11N	:= TFONT():New("ARIAL",11,11,,.T.,,,,.T.,.F.) ///Fonte 11 Negrito
	Private oFont12		:= TFONT():New("ARIAL",12,12,,.F.,,,,.T.,.F.) ///Fonte 12 Normal
	Private oFont12NS	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.T.) ///Fonte 12 Negrito e Sublinhado
	Private oFont12N	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.F.) ///Fonte 12 Negrito
	Private oFont13		:= TFONT():New("ARIAL",13,13,,.F.,,,,.T.,.F.) ///Fonte 13 Normal
	Private oFont13NS	:= TFONT():New("ARIAL",13,13,,.T.,,,,.T.,.T.) ///Fonte 13 Negrito e Sublinhado
	Private oFont13N	:= TFONT():New("ARIAL",13,13,,.T.,,,,.T.,.F.) ///Fonte 13 Negrito
	Private oFont16 	:= TFONT():New("ARIAL",16,16,,.F.,,,,.T.,.F.) ///Fonte 16 Normal
	Private oFont16N	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.F.) ///Fonte 16 Negrito
	Private oFont16NS	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.T.) ///Fonte 16 Negrito e Sublinhado
	Private oFont20N	:= TFONT():New("ARIAL",20,20,,.T.,,,,.T.,.F.) ///Fonte 20 Negrito
	Private oFont22N	:= TFONT():New("ARIAL",22,22,,.T.,,,,.T.,.F.) ///Fonte 22 Negrito

	///////////////////////////////////////////////////////////////////////
	///Variaveis Impressao                                             ////
	///////////////////////////////////////////////////////////////////////
	Private cStartPath
	Private nLin 		:= 100
	Private oPrint		:= TmsPrinter():New("")
	Private nPag		:= 1

	////////////////////////////////////////////////////////////////////////
	///Outras Variaveis
	////////////////////////////////////////////////////////////////////////
	Private cPerg   := "TRETR007"
	Private cFilZE3 := xFilial("ZE3")  //Tabela de amostra de combustivel

	////////////////////////////////////////////////////////////////////////
	////Tamanho do Papel A4
	///////////////////////////////////////////////////////////////////////
	oPrint:SetPaperSize(DMPAPER_A4)

	////////////////////////////////////////////////////////////////////////
	/////Orientacao do papel (Retrato ou Paisagem)
	////////////////////////////////////////////////////////////////////////
	//oPrint:SetLandscape() ///Define a orientacao da impressao como paisagem
	oPrint:SetPortrait()///Define a orientacao da impressao como retrato

	////////////////////////////////////////////////////////////////////////
	///Cria as perguntas no SX1
	////////////////////////////////////////////////////////////////////////
	ValidPerg()
	If !Pergunte(cPerg,.t.)
		Return
	Endif

	cNumDe	:= mv_par01
	cNumAte	:= mv_par02

	cQry := "SELECT ZE3_FILIAL, ZE3_NUMERO, ZE3_NOTA, ZE3_SERIE, ZE3_DATA, ZE3_MOTORI "
	cQry += " FROM "+RetSqlName("ZE3")+" ZE3 "
	cQry += " WHERE ZE3.D_E_L_E_T_ <> '*' "
	cQry += "     AND ZE3_FILIAL = '"+cFilZE3+"'  "
	cQry += "     AND ZE3_NOTA BETWEEN '"+cNumDe+"' AND '"+cNumAte+"'  "

	If SELECT("TRB") > 0
		TRB->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "TRB"

	If TRB->(!EOF())

		While TRB->(!EOF())
			
			fCabecalho()

			oPrint:Box(nLin,145,nLin+210,2100)

			oPrint:Say(nLin, 155, AllTrim('Nr. Da Nota Fiscal:'), oFont12N)
			oPrint:Say(nLin, 650, AllTrim(TRB->ZE3_NOTA)+"-"+TRB->ZE3_SERIE, oFont12)
			nLin+=70
			oPrint:Say(nLin, 155, AllTrim('Data Recebimento:'), oFont12N)
			oPrint:Say(nLin, 650, AllTrim(DTOC(STOD(TRB->ZE3_DATA))), oFont12)
			nLin+=70
			oPrint:Say(nLin, 155, AllTrim('Motorista:'), oFont12N)
			oPrint:Say(nLin, 650, AllTrim(TRB->ZE3_MOTORI)+" - "+Posicione("DA4",3,xFilial("DA4")+TRB->ZE3_MOTORI,"DA4_NOME"), oFont12)
			nlin+= 140

			cQry2 := "SELECT ZE4_PRODUT, ZE4_TQ, ZE4_QRINI, ZE4_QRFIM "
			cQry2 += " FROM "+RetSqlName("ZE4")+" ZE4 "
			cQry2 += " WHERE ZE4.D_E_L_E_T_ <> '*' "
			cQry2 += "     AND ZE4_FILIAL = '"+TRB->ZE3_FILIAL+"'  "
			cQry2 += "     AND ZE4_NUMERO = '"+TRB->ZE3_NUMERO+"'  "
			cQry2 += " ORDER BY ZE4_NUMERO, ZE4_TQ  "

			If SELECT("TRB2") > 0
				TRB2->(DBCLOSEAREA())
			Endif

			cQry2 := ChangeQuery(cQry2)
			TcQuery cQry2 New Alias "TRB2"

			While TRB2->(!EOF())

				If nLin+420 > 3200
					oPrint:EndPage()
					fCabecalho()
				Endif
				
				oPrint:Say(nLin, 145, AllTrim('Tq:'), oFont12N)
				oPrint:Say(nLin, 650, AllTrim(TRB2->ZE4_TQ), oFont12)
				nlin+= 70
				oPrint:Say(nLin, 145, AllTrim('Produto:'), oFont12N)
				oPrint:Say(nLin, 650, AllTrim(TRB2->ZE4_PRODUT)+" - "+Posicione("SB1",1,xFilial("SB1")+ZE4->ZE4_PRODUT,"B1_DESC"), oFont12)
				nlin+= 70
				oPrint:Say(nLin, 145, AllTrim('Medição antes Descarreg.:'), oFont12N)
				oPrint:Say(nLin, 650, Transform((TRB2->ZE4_QRINI),"@e 999"), oFont12)
				nLin+=70
				oPrint:Say(nLin, 145,AllTrim('Medição apos Descarreg.:'), oFont12N)
				oPrint:Say(nLin, 650, Transform((TRB2->ZE4_QRFIM),"@e 999"), oFont12)
				nLin+=70
				oPrint:Say(nLin, 145, AllTrim('Diferença:'), oFont12N)
				oPrint:Say(nLin, 650,Transform((TRB2->ZE4_QRFIM-TRB2->ZE4_QRINI),"@e 999"), oFont12)
				nLin+=70
				oPrint:Line(nLin,145,nLin,2100)
				nLin+=20

				TRB2->(DbSkip())

				If TRB2->(EOF())
					nLin+=70
				Endif
			EndDo
			
			oPrint:EndPage()

			TRB->(DbSkip())
		EndDo
		
		TRB2->(DbCloseArea())

		///////////////////////////////////////////////////////////////////////////////////////
		////Visualiza a impressao
		///////////////////////////////////////////////////////////////////////////////////////
		oPrint:Preview()

	Endif

	TRB->(DbCloseArea())

Return

/*/{Protheus.doc} fCabecalho
Cabeçalho
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function fCabecalho()


	oPrint:StartPage()
	cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")
	nLin := 147

	oPrint:Box(nLin,145,nLin+165,540)
	oPrint:SayBitmap(nLin+30, 165, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 342, 109)

	oPrint:Box(nLin,540,nLin+165,2100)
	cTodaStr := "Controle de Recebimento de Combustivel"
	oPrint:Say(nLin+30, 1195, cTodaStr, oFont12n,,,,2)

	nLin+=180

Return NIL

/*/{Protheus.doc} ValidPerg
Cria perguntas
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ValidPerg()

	cPerg 	:=	PADR(cPerg,10)

	U_uAjusSx1( cPerg,"01","Numero NF De          ?","."     ,"."       ,"mv_CH1","C",09,0,0,"G","","SF1","","","MV_PAR01","","","","","","","","","","","","","","","","")
	U_uAjusSx1( cPerg,"02","Numero NF Ate         ?","."     ,"."       ,"mv_CH2","C",09,0,0,"G","","SF1","","","MV_PAR02","","","","","","","","","","","","","","","","")

Return
