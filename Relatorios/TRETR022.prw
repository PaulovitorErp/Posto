
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"
#include "fwprintsetup.ch"

#define DMPAPER_A4 9 // A4 210 x 297 mm
#define IMP_PDF 6 // PDF

Static lSrvPDV := SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV
Static lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.)
Static SIMBDIN := Alltrim(SuperGetMV("MV_SIMB1",,"R$"))

/*/{Protheus.doc} TRETR022
Gera��o de relat�rio geral de caixa, listando o resumo geral de movimenta��es dos caixas, independente do caixa (Operador/Novimento/PDV/Esta��o). 
O relat�rio ser� emitido pela data informada (par�metro).
O relat�rio ser� emitido na retaguarda, atrav�s de um nova op��o (outras a��es) da rotina de Conferencia de Caixa (TRETA028).

@type function
@version 12.1.33
@author Pablo Nunes
@since 02/05/2022
/*/
User Function TRETR022()

	Local cMsgAguarde := "Consulta do fluxo de caixa do operador (Movimento Processos de Venda)..."
	Local nI := 0
	Local aSLW := {}
	Local lOk := .T.
	Local cSGBD	:= AllTrim(Upper(TcGetDb())) // -- Banco de dados atulizado (Para embientes TOP) 			 	

    Private _aListSLW := {}
	Private cPerg := "TRETR022"
    Private nTipoRel := 1 //Tipo de Impress�o? - 1=Sint�tico/2=Anal�tico
	Private nQuebra := 1 //Imprime uma se��o por p�gina? - 1=Sim/2=N�o
	Private dDtAbert := CtoD("")

	If !fValidPerg()
		Return
	Else
		nTipoRel := MV_PAR01 //1=Sintetico;2=Analitico
		nQuebra  := MV_PAR02 //Imprime uma se��o por p�gina? - 1=Sim/2=N�o
		dDtAbert := MV_PAR03 //Data de abertura
	EndIf

    cQry := "SELECT SLW.* "
    cQry += " FROM "+RetSqlName("SLW")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SLW "
    cQry += " WHERE SLW.D_E_L_E_T_= ' ' "
	cQry += " AND LW_FILIAL = '" + xFilial("SLW") + "' "
	cQry += " AND LW_DTABERT = '" + DtoS(dDtAbert) + "' "
    //cQry += " AND (LW_CONFERE = '1' OR LW_CONFERE = '2') "
    cQry += " ORDER BY LW_FILIAL, LW_PDV, LW_OPERADO, LW_DTABERT, LW_NUMMOV "

    If Select("TSLW") > 0
        TSLW->(DbCloseArea())
    EndIf
    
    cQry := ChangeQuery(cQry)
    TcQuery cQry New Alias "TSLW" // Cria uma nova area com o resultado do query

 	TSLW->(DbGoTop())

	While TSLW->(!Eof())
		//Verifica se o caixa foi conferido
		If !(TSLW->LW_CONFERE == '1' .Or. TSLW->LW_CONFERE == '2' )
			MsgAlert("Primeiramente realize o fechamento e a confer�ncia do caixa.","Aten��o")
			lOk := .F.
			Exit //sai do While
		Else
			aSLW := {TSLW->LW_OPERADO, TSLW->LW_NUMMOV, TSLW->LW_PDV, TSLW->LW_ESTACAO, StoD(TSLW->LW_DTABERT), TSLW->LW_HRABERT, iif(empty(TSLW->LW_DTFECHA),dDataBase,StoD(TSLW->LW_DTFECHA)), iif(empty(TSLW->LW_HRFECHA),SubStr(Time(),1,5),TSLW->LW_HRFECHA)}
			aadd(_aListSLW, aSLW)
		EndIf
		TSLW->(DbSkip())
	EndDo

    TSLW->(DbCloseArea())

	//Variaveis de Tipos de fontes que podem ser utilizadas no relat�rio
	//Private oFont6		:= TFONT():New("ARIAL",06,06,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 6 Normal
	//Private oFont6N 	:= TFONT():New("ARIAL",06,06,,.T.,,,,.T.,.F.) ///Fonte 6 Negrito
	Private oFont8		:= TFONT():New("ARIAL",08,08,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 8 Normal
	Private oFont8N 	:= TFONT():New("ARIAL",08,08,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
	Private oFont10 	:= TFONT():New("ARIAL",10,10,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 10 Normal
	//Private oFont10S	:= TFONT():New("ARIAL",10,10,.T.,.F.,5,.T.,5,.T.,.T.) ///Fonte 10 Sublinhando
	Private oFont10N 	:= TFONT():New("ARIAL",10,10,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
	//Private oFont12		:= TFONT():New("ARIAL",12,12,,.F.,,,,.T.,.F.) ///Fonte 12 Normal
	//Private oFont12NS	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.T.) ///Fonte 12 Negrito e Sublinhado
	Private oFont12N	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.F.) ///Fonte 12 Negrito
	//Private oFont14		:= TFONT():New("ARIAL",14,14,,.F.,,,,.T.,.F.) ///Fonte 14 Normal
	//Private oFont14NS	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.T.) ///Fonte 14 Negrito e Sublinhado
	//Private oFont14N	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.F.) ///Fonte 14 Negrito
	//Private oFont16 	:= TFONT():New("ARIAL",16,16,,.F.,,,,.T.,.F.) ///Fonte 16 Normal
	Private oFont16N	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.F.) ///Fonte 16 Negrito
	//Private oFont16NS	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.T.) ///Fonte 16 Negrito e Sublinhado
	//Private oFont20N	:= TFONT():New("ARIAL",20,20,,.T.,,,,.T.,.F.) ///Fonte 20 Negrito
	//Private oFont22N	:= TFONT():New("ARIAL",22,22,,.T.,,,,.T.,.F.) ///Fonte 22 Negrito

	//Variveis para impress�o
	Private cStartPath
	Private nLin 		:= 50
	Private oPrint		:= TMSPRINTER():New("")
	Private oBrush1		:= TBrush():New(,CLR_HGRAY)
	Private nPag		:= 1

	Private aFormasHab	:= U_TR028FHA()

	//adiciona uma posi��o de controle da impress�o da sess�o: size=9
	For nI:=1 to Len(aFormasHab)
		aAdd(aFormasHab[nI],.F.) //size=9
	Next nI

	//se relat�rio anal�tico, mostra tela para marcar/desmarcar sess�o
	If nTipoRel == 2 //1=Sintetico;2=Analitico
		If !UPergFormas()
			Return
		EndIf
	EndIf

	//Define Tamanho do Papel
	#define DMPAPER_A4 9 //Papel A4
	oPrint:setPaperSize( DMPAPER_A4 )

	//Orientacao do papel (Retrato ou Paisagem)
	oPrint:SetPortrait()///Define a orientacao da impressao como retrato
	//oPrint:SetLandscape() ///Define a orientacao da impressao como paisagem

	Cabecalho()

	oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
	oPrint:Box( nLin,45,nLin+55,2400 )
	oPrint:Say(nLin,1200, "Resumo Movimenta��o de Caixa", oFont12N,,,,2)
	nLin+= 55

	oPrint:Box( nLin,45,nLin+55,2400 )
	oPrint:Say(nLin+5,55, "Movimenta��o", oFont10N)
	oPrint:Say(nLin+5,2350, "Vlr. Apurado (+/-)", oFont10N,,,,1)
	nLin+= 70

	LjMsgRun(cMsgAguarde,"Relat�rio Conferencia de Caixa",{|| ImpRelSint() })

	if nTipoRel == 2
		LjMsgRun(cMsgAguarde,"Relat�rio Conferencia de Caixa",{|| ImpRelAnalit() })
	endif

	//Finaliza Relat�rio
	Rod()

	//Visualiza a impressao
	oPrint:Preview()

Return

/*/{Protheus.doc} fValidPerg
Perguntas SX1

@type function
@version 12.1.33
@author Pablo Nunes
@since 11/04/2022
/*/
Static Function fValidPerg()

	Local aHelpPor := {}, aHelpEng := {}, aHelpSpa := {}

	U_uAjusSx1( cPerg, "01","Tipo de Impress�o?","Tipo de Impress�o?","Tipo de Impress�o?","mv_ch1","N",1,0,0,"C","","","","",;
		"mv_par01","Sint�tico","","","","Anal�tico","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

	U_uAjusSx1( cPerg, "02","Imprime uma se��o por p�gina?","Imprime uma se��o por p�gina?","Imprime uma se��o por p�gina?","mv_ch2","N",1,0,0,"C","","","","",;
		"mv_par02","N�o","","","","Sim","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

	U_uAjusSx1( cPerg, "03","Data de abertura?","Data de abertura?","Data de abertura?","mv_ch3","D",10,0,0,"G","","","","",;
		"mv_par03","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

Return Pergunte(cPerg,.T.)

//----------------------------------------------------------------------
//Marca quais se��es ser�o impressas
//----------------------------------------------------------------------
Static Function UPergFormas()
	Local nI := 0
	Local aRet := {}
	Local aParamBox := {}
	Local lRet := .T.
	Local aItem := {}
	Local aMvPar := {}
	Private cCadastro := "TRETA028"

	For nI:=1 to Len(aFormasHab)
		If !Empty(aFormasHab[nI][6])
			aAdd(aParamBox,{5,aFormasHab[nI][1]+" - "+aFormasHab[nI][2],.T.,180,"",.F.})
			aAdd(aItem,nI)
		EndIf
		aFormasHab[nI][len(aFormasHab[nI])] := .F. //size=9
	Next nI

	For nI := 1 To Len( aItem )
		aAdd( aMvPar, &( "MV_PAR" + StrZero( nI, 2, 0 ) ) )
	Next nI

	If lRet := ParamBox(aParamBox,"Marque as Sess�es Rel. Anal�tico",@aRet)
		For nI:=1 to Len(aRet)
			aFormasHab[aItem[nI]][len(aFormasHab[aItem[nI]])] := aRet[nI]
		Next nI
	Endif

	For nI := 1 To Len( aItem )
		&( "MV_PAR" + StrZero( nI, 2, 0 ) ) := aMvPar[ nI ]
	Next nI

Return lRet

//--------------------------------------------------------------------------------------
// Monta cabe�alho do relat�rio
//--------------------------------------------------------------------------------------
Static Function Cabecalho(cTitle)

    Local nX := 1
	Default cTitle := "Movimenta��o Geral de Caixas"

	oPrint:StartPage() // Inicia uma nova pagina
	cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")

	nLin:=80
	oPrint:SayBitmap(nLin, 60, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 400, 128)///Impressao da Logo
	oPrint:Say(nLin, 2350, "Pagina: " + strzero(nPag,3), oFont8N,,,,1)
	oPrint:Say(nLin+50, 1200, cTitle, oFont16N,,,,2)
	nLin+=30
	oPrint:Say(nLin+30, 2350, DTOC(dDataBase), oFont8N,,,,1)
	nLin+=70
	oPrint:Say(nLin, 2350, TIME(), oFont8N,,,,1)
	nLin:=250

	oPrint:FillRect( {nLin,45, nLin+50, 2400}, oBrush1 )
	oPrint:Box( 50,45,300,2400 )
	oPrint:Line (nLin, 45, nLin, 2400)
	oPrint:Say(nLin+5, 80, "Data Abertura: "+DTOC(dDtAbert), oFont8N)
	//oPrint:Say(nLin+5, 550, "Turno: "+TSLW->LW_NUMMOV	, oFont8N)
	//oPrint:Say(nLin+5, 770, "Operador: "+Posicione("SA6",1,xFilial("SA6")+TSLW->LW_OPERADO,"A6_NOME")	, oFont8N)
    cPdvs := ""
    For nX:=1 to Len(_aListSLW)
        cPdvs += "["+Alltrim(_aListSLW[nX][3])+"]["+AllTrim(_aListSLW[nX][2])+"]" + " / "
    Next nX
    cPdvs := SubStr(cPdvs,1,Len(cPdvs)-3)
	oPrint:Say(nLin+5, 500, "PDV(s) + Turno(s): "+cPdvs, oFont8N)

	nLin+=100

Return

//--------------------------------------------------------------------------------------
// Monta rodap� do relat�rio
//--------------------------------------------------------------------------------------
Static Function Rod()

	nLin := 3350
	oPrint:Line (nLin, 45, nLin, 2400)
	oPrint:EndPage()

Return

//--------------------------------------------------------------------------------------
// Faz impress�o das formas, sinteticamente
//--------------------------------------------------------------------------------------
Static Function ImpRelSint()

	Local nValForm := 0
	Local nTotSaida := 0
	Local nTotEntra := 0
	Local nSaldoDin := 0
	Local nX := 0

	//forma com sinal de +
	For nX := 1 to len(aFormasHab)
		if aFormasHab[nX][3] == "+"
			oPrint:Say(nLin,55, Capital(aFormasHab[nX][2]) , oFont10)
			nValForm := U_TR028DTF(aFormasHab[nX][1], 2)
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (+)", oFont10,,,,1)
			nLin+= 60

			nTotSaida += nValForm
		endif
	Next nX

	oPrint:Line (nLin, 45, nLin, 2400)
	nLin+= 10
	oPrint:Say(nLin,55, "Total Sa�das:", oFont10N)
	oPrint:Say(nLin,2350, Transform(nTotSaida,"@E 999,999,999.99")+" (+)", oFont10N,,,,1)
	nLin+= 100

	//forma com sinal de -
	For nX := 1 to len(aFormasHab)
		if aFormasHab[nX][3] == "-"
			oPrint:Say(nLin,55, Capital(aFormasHab[nX][2]) , oFont10)
			nValForm := U_TR028DTF(aFormasHab[nX][1], 2)
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (-)", oFont10,,,,1)
			nLin+= 60

			nTotEntra += nValForm
		endif
	Next nX

	oPrint:Line (nLin, 45, nLin, 2400)
	nLin+= 10
	oPrint:Say(nLin,55, "Total Entradas:", oFont10N)
	oPrint:Say(nLin,2350, Transform(nTotEntra,"@E 999,999,999.99")+" (-)", oFont10N,,,,1)
	nLin+= 100

	oPrint:Box( nLin,45,nLin+55,2400 )
	if nTotEntra - nTotSaida   > 0
		oPrint:Say(nLin,55, "SOBRA DE CAIXA", oFont10N)
	else
		oPrint:Say(nLin,55, "FALTA DE CAIXA", oFont10N)
	endif
	oPrint:Say(nLin,2350, Transform(nTotEntra - nTotSaida,"@E 999,999,999.99")+" (=)", oFont10N,,,,1)
	nLin+= 80

	//--------------------------------------------------------------------------
	//Resumo Dinheiro
	//--------------------------------------------------------------------------
	oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
	oPrint:Box( nLin,45,nLin+55,2400 )
	oPrint:Say(nLin,1200, "Resumo Movimenta��o de Dinheiro em Esp�cie", oFont10N,,,,2)
	nLin+= 55

	oPrint:Box( nLin,45,nLin+55,2400 )
	oPrint:Say(nLin+5,55, "Movimenta��o", oFont10N)
	oPrint:Say(nLin+5,2350, "Vlr. Apurado (+/-)", oFont10N,,,,1)
	nLin+= 70

	//(+) Suprimentos
	oPrint:Say(nLin,55, "Suprimentos no Caixa", oFont10)
	nValForm := U_TR028DTF("SU", 2)
	nSaldoDin += nValForm
	oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (+)", oFont10,,,,1)
	nLin+= 60

	//(+) Vendas Recebidas em Dinheiro
	oPrint:Say(nLin,55, "Vendas Recebidas em Dinheiro", oFont10)
	if lSrvPDV
		aDados := U_TR028BE4("PDV", 2, {"L4_VALOR"},,"Alltrim(SL4->L4_FORMA) == '"+SIMBDIN+"'")
	else
		aDados := U_TR028BE1({"E1_VALOR"}, "RTRIM(E1_TIPO) = '"+SIMBDIN+"'",,,.T.,.F.)
	endif
	nValForm := 0
	For nX:=1 To Len(aDados)
		nValForm += aDados[nX][1]
	Next
	nSaldoDin += nValForm
	oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (+)", oFont10,,,,1)
	nLin+= 60

	//(-) Trocos em Dinheiro de Vendas
	oPrint:Say(nLin,55, "Trocos em Dinheiro (Vendas)", oFont10)
	nValForm := U_T028TTV(4)
	nSaldoDin -= nValForm
	oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (-)", oFont10,,,,1)
	nLin+= 60

	if lMvPosto

		//(-) Sa�da Dinheiro Compensa��o Valores
		if SuperGetMV("TP_ACTCMP",,.F.)
			nValForm := 0
			if lSrvPDV
				cCondicao := GetFilUC0("PDV", .T.)
				bCondicao 	:= "{|| " + cCondicao + " }"
				UC0->(DbClearFilter())
				UC0->(DbSetFilter(&bCondicao,cCondicao))
				UC0->(DbGoTop())
				While UC0->(!Eof())
					nValForm += UC0->UC0_VLDINH
					UC0->(DbSkip())
				enddo
				UC0->(DbClearFilter())
			else
				aDados := U_TR028BE1({"E1_VALOR"}, "RTRIM(E1_TIPO) = 'NCC'",,,.F.,.T.)
				For nX:=1 To Len(aDados)
					nValForm += aDados[nX][1]
				Next
			endif

			oPrint:Say(nLin,55, "Sa�da Dinheiro Compensa��o Valores", oFont10)
			nSaldoDin -= nValForm
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (-)", oFont10,,,,1)
			nLin+= 60

		endif

		//+ Vale Servi�o Pr�-Pago Recebidos
		if SuperGetMV("TP_ACTDP",,.F.)
			oPrint:Say(nLin,55, "Vale Servi�o Pr�-Pago Recebidos", oFont10)
			nValForm := U_T028TVLS(4,,,,.T.)
			nSaldoDin += nValForm
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (+)", oFont10,,,,1)
			nLin+= 60
		endif

		//+ Depositos no PDV
		if SuperGetMV("TP_ACTDP",,.F.)
			oPrint:Say(nLin,55, "Depositos no PDV", oFont10)
			nValForm := U_TR028DTF("DP", 2)
			nSaldoDin += nValForm
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (+)", oFont10,,,,1)
			nLin+= 60
		endif

		if SuperGetMV("TP_ACTSQ",,.F.)
			nValForm := 0
			//- Saques Pr�
			nValForm += U_TR028DTF("SQ", 2)
			//- Vale Motorista (p�s)
			nValForm += U_TR028DTF("VLM", 2)
			//retiro os cheque troco desses valores
			if SuperGetMV("TP_ACTCHT",,.F.)
				nValForm -= U_T028TCHT(4,,,.F.,.F.,.T.)
			endif

			oPrint:Say(nLin,55, "Sa�da de Saque/Vale Motorista em Dinheiro", oFont10)
			nSaldoDin -= nValForm
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (-)", oFont10,,,,1)
			nLin+= 60
		endif

	endif

	//(-) Sangria
	oPrint:Say(nLin,55, "Sangrias de Caixa", oFont10)
	nValForm := U_TR028DTF("SG", 2)
	nSaldoDin -= nValForm
	oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (-)", oFont10,,,,1)
	nLin+= 60

	//(=) Total
	oPrint:Line (nLin, 45, nLin, 2400)
	nLin+= 10
	oPrint:Say(nLin,55, "TOTAL DINHEIRO:", oFont10N)
	oPrint:Say(nLin,2350, Transform(nSaldoDin,"@E 999,999,999.99")+" (=)", oFont10N,,,,1)
	nLin+= 100

Return

//--------------------------------------------------------------------------------------
// Faz impress�o das formas, analiticamente
//--------------------------------------------------------------------------------------
Static Function ImpRelAnalit()

	Local cFuncton := ""
	Local bExFunc := {|cFunc| ExistBlock(cFunc) }
	Local nX

	For nX := 1 to len(aFormasHab)
		cFuncton := aFormasHab[nX][6]
		if !Empty(cFuncton) .and. aFormasHab[nX][9]
			if Eval(bExFunc, cFuncton) //ExistBlock(cFuncton)
				ExecBlock(cFuncton,.F.,.F., {2, aFormasHab[nX][2], aFormasHab[nX][1]})
			endif
		endif
	Next nX

Return
