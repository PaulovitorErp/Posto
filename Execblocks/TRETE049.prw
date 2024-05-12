#include "protheus.ch"
#include "topconn.ch"
#Include "TBICONN.CH"

/*/{Protheus.doc} User Function TRETE049
Monitor de Notas Fiscais de Fatura
@type  Function
@author danilo
@since 18/03/2024
@version 1
/*/
User Function TRETE049(aFaturas, lFluxoFat)

    Local aObjects, aSizeAut, aInfo, aPosObj
    Local cTitulo := "Faturamento Manual V2 - Monitor de Notas Fiscais"
    Local oBtn1, oBtn2, oBtn3, oBtn4, oBtn5
    Local bMarkLin := {|x| iif(x[1]=="LBNO", x[1]:="LBOK", x[1]:="LBNO")  }
    Local oFontGrid := TFont():New("Arial",,018,,.T.,,,,,.F.,.F.)
    
	Local aHeaderEx := {}
	Local aColsEx := {}

    Default aFaturas := {}
    Default lFluxoFat := .F.

    Private aT49CpFat := {"MARK","LEG","E1_FILIAL","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_CLIENTE","E1_LOJA","A1_NOME","A1_XCLASSE","E1_EMISSAO","E1_VENCTO","E1_VALOR","E1_VLRREAL"}
    Private oGridFat
    Private aT49CpNfO := {"MARK","LEG","F2_FILIAL","F2_SERIE","F2_DOC","F2_ESPECIE","F2_EMISSAO","F2_VALBRUT","MDL_SERIE","MDL_NFCUP","F2_DTLANC","F2_MENNOTA"}
    Private oGridNfOri
    Private lMARKALL := .F.

    Private __XVEZ 		:= "0"
    Private __ASC       := .T.

    Private oChkOcultar
    Private lChkOcultar := lFluxoFat

    Private oChkSemNfe
    Private lChkSemNfe := .F.

    Private aFaturasPar := aFaturas
    Private aFatMonitor := {}

    Private lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)

    if empty(aFaturas)
        MsgInfo("Nenhuma fatura selecionada para monitoramento!")
        Return
    endif

    aObjects := {}
    aAdd(aObjects,{100, 090, .T., .T.})
    aAdd(aObjects,{100, 010, .F., .F.}) 
	aSizeAut := MsAdvSize()
    aInfo 	:= {aSizeAut[1],aSizeAut[2],aSizeAut[3],aSizeAut[4],3,3}
	aPosObj := MsObjSize(aInfo,aObjects,.T.)

    Static oDlgT049

    DEFINE MSDIALOG oDlgT049 TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6]-100,aSizeAut[5]-60 OF oMainWnd PIXEL
    
    //GRID DE FATURAS
    @ 005, aPosObj[1,2]+5 SAY oSay1 PROMPT "Faturas Geradas" SIZE 100, 017 OF oDlgT049 FONT oFontGrid COLORS 0, 16777215 PIXEL

    aHeaderEx := U_MontaHeader( aT49CpFat)
    aHeaderEx[aScan( aT49CpFat,"E1_VALOR")][1] := "Vlr.Fatura"
    aHeaderEx[aScan( aT49CpFat,"E1_VLRREAL")][1] := "Vlr.Bruto"
    
    aadd(aColsEx, U_MontaDados("SE1", aT49CpFat, .T.,,,.T.))
	oGridFat := MsNewGetDados():New( aPosObj[1,1]-18,aPosObj[1,2],((aPosObj[1,3]-50)/2)-10,aPosObj[1,4] - 27,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oDlgT049, aHeaderEx, aColsEx)
    oGridFat:oBrowse:bchange := {|| RefreshNotasFat() }
    oGridFat:oBrowse:bLDblClick := {|| Eval(bMarkLin, oGridFat:aCols[oGridFat:nAt]), MarkChild(.F.) }
	oGridFat:oBrowse:bHeaderClick := {|oBrw,nCol| iif(nCol > 1, U_UOrdGrid(@oGridFat, @nCol), iif(lMARKALL,(aEval(oGridFat:aCols, bMarkLin),oBrw:Refresh(),oBrw:SetFocus(),MarkChild(.T.),lMARKALL:=!lMARKALL) ,lMARKALL:=!lMARKALL) )}

    //Legendas Faturas
	@ ((aPosObj[1,3]-50)/2)-8, aPosObj[1,2] BITMAP oLeg ResName "BR_LARANJA" OF oDlgT049 Size 10, 10 NoBorder When .F. PIXEL
	@ ((aPosObj[1,3]-50)/2)-7, aPosObj[1,2]+10 SAY "Fatura com apenas NFe na origem" OF oDlgT049 Color CLR_BLACK PIXEL

    @ ((aPosObj[1,3]-50)/2)-8, 105 BITMAP oLeg ResName "BR_VERMELHO" OF oDlgT049 Size 10, 10 NoBorder When .F. PIXEL
	@ ((aPosObj[1,3]-50)/2)-7, 115 SAY "Há NFCe de origem sem NFe gerada" OF oDlgT049 Color CLR_BLACK PIXEL

    @ ((aPosObj[1,3]-50)/2)-8, 220 BITMAP oLeg ResName "BR_AZUL" OF oDlgT049 Size 10, 10 NoBorder When .F. PIXEL
	@ ((aPosObj[1,3]-50)/2)-7, 230 SAY "NFe gerada sobre NFCe de origem" OF oDlgT049 Color CLR_BLACK PIXEL

	@ ((aPosObj[1,3]-50)/2)-8, 330 BITMAP oLeg ResName "BR_VERDE" OF oDlgT049 Size 10, 10 NoBorder When .F. PIXEL
	@ ((aPosObj[1,3]-50)/2)-7, 340 SAY "NFe gerada sobre NFCe de origem - Autorizada" OF oDlgT049 Color CLR_BLACK PIXEL

    @ 005,aPosObj[1,4] - 340 CHECKBOX oChkSemNfe VAR lChkSemNfe PROMPT "Mostrar apenas faturas com NFe s/Cupom não gerada/autorizada"  Size 180, 007 PIXEL OF oDlgT049 COLORS 0, 16777215 PIXEL
	oChkSemNfe:bChange := ({|| FWMsgRun(,{|oSay| LoadFatura(oSay, .T.)},'Aguarde','carregando dados...') })

    @ 005,aPosObj[1,4] - 155 CHECKBOX oChkOcultar VAR lChkOcultar PROMPT "Ocultar faturas com apenas NFe na origem"  Size 130, 007 PIXEL OF oDlgT049 COLORS 0, 16777215 PIXEL
	oChkOcultar:bChange := ({|| FWMsgRun(,{|oSay| LoadFatura(oSay, .T.)},'Aguarde','carregando dados...') })


    //GRID DE NOTAS FISCAIS DE ORIGEM
    @ ((aPosObj[1,3]-50)/2)+10, aPosObj[1,2]+5 SAY oSay1 PROMPT "Cupons/Notas Origem" SIZE 100, 017 OF oDlgT049 FONT oFontGrid COLORS 0, 16777215 PIXEL

    aHeaderEx := U_MontaHeader( aT49CpNfO)
    aHeaderEx[aScan( aT49CpNfO,"MDL_SERIE")][1] := "Serie NFe"
    aHeaderEx[aScan( aT49CpNfO,"MDL_NFCUP")][1] := "NFe s/ Cupom"
    aHeaderEx[aScan( aT49CpNfO,"F2_DTLANC")][1] := "Emissão NFe"
    aHeaderEx[aScan( aT49CpNfO,"F2_MENNOTA")][1] := "Mensagens"

    aColsEx := {}    
    aadd(aColsEx, U_MontaDados("SF2", aT49CpNfO, .T.,,.T.))
	oGridNfOri := MsNewGetDados():New( ((aPosObj[1,3]-50)/2)+20,aPosObj[1,2],aPosObj[1,3]-70, aPosObj[1,4] - 27,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oDlgT049, aHeaderEx, aColsEx)
    oGridNfOri:oBrowse:bLDblClick := {|| Eval(bMarkLin, oGridNfOri:aCols[oGridNfOri:nAt])  }
	oGridNfOri:oBrowse:bHeaderClick := {|oBrw,nCol| iif(nCol > 1, U_UOrdGrid(@oGridNfOri, @nCol), iif(lMARKALL,(aEval(oGridNfOri:aCols, bMarkLin),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL) ,lMARKALL:=!lMARKALL) )}

    //Legendas nota fiscal de origem
	@ aPosObj[1,3]-68, aPosObj[1,2] BITMAP oLeg ResName "BR_VERMELHO" OF oDlgT049 Size 10, 10 NoBorder When .F. PIXEL
	@ aPosObj[1,3]-67, aPosObj[1,2]+10 SAY "NFe não gerada" OF oDlgT049 Color CLR_BLACK PIXEL

	@ aPosObj[1,3]-68, 080 BITMAP oLeg ResName "BR_AZUL" OF oDlgT049 Size 10, 10 NoBorder When .F. PIXEL
	@ aPosObj[1,3]-67, 090 SAY "NFe gerada" OF oDlgT049 Color CLR_BLACK PIXEL

	@ aPosObj[1,3]-68, 150 BITMAP oLeg ResName "BR_VERDE" OF oDlgT049 Size 10, 10 NoBorder When .F. PIXEL
	@ aPosObj[1,3]-67, 160 SAY "NFe autorizada" OF oDlgT049 Color CLR_BLACK PIXEL

    //RODAPE DA TELA
    @ aPosObj[1,3]-60, aPosObj[1,2]+5 SAY oSay3 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4] - 37, 007 OF oDlgT049 COLORS CLR_GRAY, 16777215 PIXEL

    @ aPosObj[1,3]-50, aPosObj[1,2]+5 BUTTON oBtn2 PROMPT "Gerar NFe" SIZE 050, 013 OF oDlgT049 ACTION DoAction(1) PIXEL
    @ aPosObj[1,3]-50, aPosObj[1,2]+60 BUTTON oBtn3 PROMPT "Estornar NFe" SIZE 050, 013 OF oDlgT049 ACTION DoAction(2) PIXEL
    @ aPosObj[1,3]-50, aPosObj[1,2]+115 BUTTON oBtn4 PROMPT "Transmitir" SIZE 050, 013 OF oDlgT049 ACTION DoAction(3) PIXEL
    @ aPosObj[1,3]-50, aPosObj[1,2]+170 BUTTON oBtn5 PROMPT "Atualizar Status SEFAZ" SIZE 070, 013 OF oDlgT049 ACTION DoAction(4) PIXEL

    @ aPosObj[1,3]-50, aPosObj[1,4] - 75 BUTTON oBtn1 PROMPT "Fechar" SIZE 040, 013 OF oDlgT049 ACTION oDlgT049:End() PIXEL

    ACTIVATE MSDIALOG oDlgT049 CENTERED ON INIT FWMsgRun(,{|oSay| LoadFatura(oSay)},'Aguarde','carregando dados...')

Return 

Static Function MarkChild(lAll)

    Local nX
    Local cMark
    Local bMarkNF := {|aNf| aNf[1] := cMark }
    Local nPosNf := len(aT49CpFat)+1
    if lAll
        for nX := 1 to len(oGridFat:aCols)
            cMark := oGridFat:aCols[nX][1]
            aEval(oGridFat:aCols[nX][nPosNf], bMarkNF)
        next nX
    else
        cMark := oGridFat:aCols[oGridFat:nAt][1]
        aEval(oGridFat:aCols[oGridFat:nAt][nPosNf], bMarkNF)
    endif
    oGridNfOri:oBrowse:Refresh()

Return

Static Function LoadFatura(oSay, lFilterOnly, lSefaz)
    
    Local nX := 0
    Local aFatTmp := {}
    Local cLegenda := ""
    Local nPosNf := len(aT49CpFat)+1
    Default lFilterOnly := .F.
    Default lSefaz := .F.

    oSay:SetText('Atualizando dados na tela...')
    oSay:Refresh()

    oGridFat:aCols := {}
    
    if empty(aFatMonitor) 

        aFatMonitor := {}

        //aFaturasPar : {cNum,cCliFat,cLojaFat,cPref,cParc,cTipo}
        SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

        for nX := 1 to len(aFaturasPar)
            
            If SE1->(DbSeek(xFilial("SE1")+aFaturasPar[nX][2]+aFaturasPar[nX][3]+aFaturasPar[nX][4]+aFaturasPar[nX][1]+aFaturasPar[nX][5]+aFaturasPar[nX][6]))

                cLegenda := ""
                aFatTmp := U_MontaDados("SE1", aT49CpFat, .T.,,,.T.) //cria uma posição a mais com um array vazio para receber as notas fiscais de origem

                //{"LEG","E1_FILIAL","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_CLIENTE","E1_LOJA","A1_NOME","A1_XCLASSE","E1_EMISSAO","E1_VENCTO","E1_VALOR","E1_VLRREAL"}
                
                aFatTmp[aScan(aT49CpFat,"E1_FILIAL")] := SE1->E1_FILIAL
                aFatTmp[aScan(aT49CpFat,"E1_PREFIXO")] := SE1->E1_PREFIXO
                aFatTmp[aScan(aT49CpFat,"E1_NUM")] := SE1->E1_NUM
                aFatTmp[aScan(aT49CpFat,"E1_PARCELA")] := SE1->E1_PARCELA
                aFatTmp[aScan(aT49CpFat,"E1_TIPO")] := SE1->E1_TIPO
                aFatTmp[aScan(aT49CpFat,"E1_CLIENTE")] := SE1->E1_CLIENTE
                aFatTmp[aScan(aT49CpFat,"E1_LOJA")] := SE1->E1_LOJA
                aFatTmp[aScan(aT49CpFat,"A1_NOME")] := Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_NOME")
                aFatTmp[aScan(aT49CpFat,"A1_XCLASSE")] := Posicione("UF6",1,xFilial("UF6")+SA1->A1_XCLASSE,"UF6_DESC")
                aFatTmp[aScan(aT49CpFat,"E1_EMISSAO")] := SE1->E1_EMISSAO
                aFatTmp[aScan(aT49CpFat,"E1_VENCTO")] := SE1->E1_VENCTO
                aFatTmp[aScan(aT49CpFat,"E1_VALOR")] := SE1->E1_VALOR
                aFatTmp[aScan(aT49CpFat,"E1_VLRREAL")] := SE1->E1_VLRREAL

                //busca as notas fiscais de origem da fatura e os status
                aFatTmp[nPosNf] := LoadNotasFat(@cLegenda, lSefaz)
                aFatTmp[aScan(aT49CpFat,"LEG")] := cLegenda

                aadd(aFatMonitor, aFatTmp)
                
            endif

        next nX

    elseif !lFilterOnly

        //apenas atualizo o status do que ja tenho carredado
        for nX := 1 to len(aFatMonitor)
            LoadNotasFat(@cLegenda, lSefaz, .F., aFatMonitor[nX][nPosNf])
            aFatMonitor[nX][aScan(aT49CpFat,"LEG")] := cLegenda
        next nX

    endif

    for nX := 1 to Len(aFatMonitor)
        if lChkOcultar .AND. aFatMonitor[nX][aScan(aT49CpFat,"LEG")] == "BR_LARANJA"
            LOOP
        endif
        if lChkSemNfe .AND. aFatMonitor[nX][aScan(aT49CpFat,"LEG")] <> "BR_VERMELHO" .AND. aFatMonitor[nX][aScan(aT49CpFat,"LEG")] <> "BR_AZUL"
            LOOP
        endif

        aadd(oGridFat:aCols, aFatMonitor[nX])
    next nX
    
    if empty(oGridFat:aCols)
        aadd(oGridFat:aCols, U_MontaDados("SE1", aT49CpFat, .T.,,,.T.))
    endif
    
    oGridFat:oBrowse:Refresh()
    oGridFat:GoTop()

Return

Static Function LoadNotasFat(cLegenda, lSefaz, lDoQuery, aNfsFat)

    Local nY := 0
    Local aNfTemp := {}
    Local aNotasFat := {}
    Local cQry := ""
    Local lHasNFe := .F.
    Local lHasNFCe := .F.
    Local lNotHasNFCup := .F.
    Local lHasNotAuth := .F.
    Local nPosRecSF2 := len(aT49CpNfO)+1
    Default lDoQuery := .T.

    MDL->(DbSetOrder(2)) // MDL_FILIAL+MDL_CUPOM+MDL_SERCUP+MDL_NFCUP+MDL_SERIE

    //{"MARK","LEG","F2_FILIAL","F2_SERIE","F2_DOC","F2_ESPECIE","F2_EMISSAO","F2_VALBRUT","MDL_SERIE","MDL_NFCUP","F2_DTLANC","F2_MENNOTA"}
    if lDoQuery
    
        cQry := "SELECT DISTINCT SF2.F2_FILIAL, SF2.F2_SERIE, SF2.F2_DOC, SF2.F2_ESPECIE, SF2.F2_EMISSAO, SF2.F2_VALBRUT, SF2.R_E_C_N_O_ AS RECSF2"
        cQry += " FROM "+RetSqlName("SF2")+" SF2 	INNER JOIN "+RetSqlName("SE1")+" SE1	ON SE1.E1_NUM		= SF2.F2_DOC"
        cQry += " 																			AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
        cQry += " 																			AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
        cQry += " 																			AND SE1.E1_LOJA		= SF2.F2_LOJA"
        cQry += " 																			AND SE1.D_E_L_E_T_	= ' '"
        cQry += " 																			AND SE1.E1_FILORIG 	= SF2.F2_FILIAL "
        cQry += " 									INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO 	= FI7.FI7_PRFORI"
        cQry += " 																			AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
        cQry += " 																			AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
        cQry += " 																			AND SE1.E1_TIPO 	= FI7.FI7_TIPORI"
        cQry += " 																			AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
        cQry += " 																			AND SE1.E1_LOJA 	= FI7.FI7_LOJORI"
        cQry += " 																			AND FI7.FI7_FILDES	= '"+SE1->E1_FILIAL+"'"
        cQry += " 																			AND FI7.FI7_PRFDES	= '"+SE1->E1_PREFIXO+"'"
        cQry += " 																			AND FI7.FI7_NUMDES	= '"+SE1->E1_NUM+"'"
        cQry += " 																			AND FI7.FI7_PARDES	= '"+SE1->E1_PARCELA+"'"
        cQry += " 																			AND FI7.FI7_TIPDES	= '"+SE1->E1_TIPO+"'"
        cQry += " 																			AND FI7.FI7_CLIDES	= '"+SE1->E1_CLIENTE+"'"
        cQry += " 																			AND FI7.FI7_LOJDES	= '"+SE1->E1_LOJA+"'"
        cQry += " 																			AND FI7.D_E_L_E_T_	= ' '"
        cQry += " 																			AND FI7.FI7_FILIAL	= '"+xFilial("FI7")+"'"
        cQry += " WHERE SF2.D_E_L_E_T_ 	= ' '"
        cQry += " ORDER BY SF2.F2_EMISSAO, SF2.F2_FILIAL, SF2.F2_SERIE, SF2.F2_DOC"

        If Select("QRYNF49") > 0
            QRYNF49->(DbCloseArea())
        Endif

        cQry := ChangeQuery(cQry)
        TcQuery cQry NEW Alias "QRYNF49"

        While QRYNF49->(!EOF())

            aNfTemp := U_MontaDados("SF2", aT49CpNfO, .T.,,.T.)
            aNfTemp[aScan(aT49CpNfO,"MARK")] := "LBNO"
            aNfTemp[aScan(aT49CpNfO,"F2_FILIAL")] := QRYNF49->F2_FILIAL
            aNfTemp[aScan(aT49CpNfO,"F2_SERIE")] := QRYNF49->F2_SERIE
            aNfTemp[aScan(aT49CpNfO,"F2_DOC")] := QRYNF49->F2_DOC
            aNfTemp[aScan(aT49CpNfO,"F2_ESPECIE")] := iif( Alltrim(QRYNF49->F2_ESPECIE)=="SPED","NFE",QRYNF49->F2_ESPECIE)
            aNfTemp[aScan(aT49CpNfO,"F2_EMISSAO")] := STOD(QRYNF49->F2_EMISSAO)
            aNfTemp[aScan(aT49CpNfO,"F2_VALBRUT")] := QRYNF49->F2_VALBRUT

            if Alltrim(QRYNF49->F2_ESPECIE) == "SPED" //nfe
                lHasNFe := .T.
                aNfTemp[aScan(aT49CpNfO,"LEG")] := "BR_VERDE"
                aNfTemp[aScan(aT49CpNfO,"F2_MENNOTA")] := "NFe Autorizada no PDV"
            else
                lHasNFCe := .T.
                VerStatusNfCup(aNfTemp, QRYNF49->F2_FILIAL, QRYNF49->F2_DOC, QRYNF49->F2_SERIE, lSefaz, @lNotHasNFCup, @lHasNotAuth)
            endif

            aNfTemp[len(aT49CpNfO)+1] := QRYNF49->RECSF2

            aadd(aNotasFat, aNfTemp)

            QRYNF49->(DbSkip())
        EndDo

        If Select("QRYNF49") > 0
            QRYNF49->(DbCloseArea())
        Endif

    else
        
        for nY := 1 to len(aNfsFat)
            SF2->(DbGoTo(aNfsFat[nY][nPosRecSF2]))
            if Alltrim(SF2->F2_ESPECIE) == "SPED" //se nao é nfe
                lHasNFe := .T.
            else
                lHasNFCe := .T.
                VerStatusNfCup(aNfsFat[nY], SF2->F2_FILIAL, SF2->F2_DOC, SF2->F2_SERIE, lSefaz, @lNotHasNFCup, @lHasNotAuth)
            endif
        next nY

    endif

    if lHasNFe .AND. !lHasNFCe
        cLegenda := "BR_LARANJA"
    elseif lHasNFCe .AND. lNotHasNFCup //se tem nfce e alguma não tem nfe de acobertamento
        cLegenda := "BR_VERMELHO"
    elseif lHasNFCe .AND. lHasNotAuth //se tenho nfce e nfe pra todas, verifico se há alguma nao autorizada
        cLegenda := "BR_AZUL"
    else 
        cLegenda := "BR_VERDE"
    endif

Return aNotasFat

Static Function VerStatusNfCup(aNfTemp, cFilNf, cDocNF, cSerieNF, lSefaz, lNotHasNFCup, lHasNotAuth)

    Local cRetorno := ""
    Local lFindMDL := .F.

    if MDL->(DbSeek(cFilNf+cDocNF+cSerieNF))
        SF2->(DbSetOrder(1)) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
        if SF2->(DbSeek(MDL->MDL_FILIAL+MDL->MDL_NFCUP+MDL->MDL_SERIE))
            lFindMDL := .T.
            aNfTemp[aScan(aT49CpNfO,"MDL_SERIE")] := MDL->MDL_SERIE
            aNfTemp[aScan(aT49CpNfO,"MDL_NFCUP")] := MDL->MDL_NFCUP
            aNfTemp[aScan(aT49CpNfO,"F2_DTLANC")] := SF2->F2_EMISSAO
        else
            aNfTemp[aScan(aT49CpNfO,"MDL_SERIE")] := ""
            aNfTemp[aScan(aT49CpNfO,"MDL_NFCUP")] := ""
            aNfTemp[aScan(aT49CpNfO,"F2_DTLANC")] := STOD("")
        endif 
    else
        aNfTemp[aScan(aT49CpNfO,"MDL_SERIE")] := ""
        aNfTemp[aScan(aT49CpNfO,"MDL_NFCUP")] := ""
        aNfTemp[aScan(aT49CpNfO,"F2_DTLANC")] := STOD("")
    endif

    if lFindMDL
        
        if SF2->F2_FIMP $ "S" 
            aNfTemp[aScan(aT49CpNfO,"LEG")] := "BR_VERDE"
            aNfTemp[aScan(aT49CpNfO,"F2_MENNOTA")] := "Nfe s/Cupom Autorizada"
        else
            if !empty(SF2->F2_FIMP) .AND. lSefaz
                cRetorno := MonitNFe(SF2->F2_FILIAL, SF2->F2_DOC, SF2->F2_SERIE)
                aNfTemp[aScan(aT49CpNfO,"F2_MENNOTA")] := iif(empty(cRetorno),"Sem Dados da NFe",cRetorno)
                if SF2->F2_FIMP $ "S" 
                    aNfTemp[aScan(aT49CpNfO,"LEG")] := "BR_VERDE"
                else
                    lHasNotAuth := .T.
                    aNfTemp[aScan(aT49CpNfO,"LEG")] := "BR_AZUL"
                endif
            else
                lHasNotAuth := .T.
                aNfTemp[aScan(aT49CpNfO,"LEG")] := "BR_AZUL"
                if !lSefaz
                    aNfTemp[aScan(aT49CpNfO,"F2_MENNOTA")] := "Nfe s/Cupom gerada, aguardando transmissão/autorização"
                endif
                if SF2->F2_FIMP $ "N"
                    aNfTemp[aScan(aT49CpNfO,"F2_MENNOTA")] := "Nfe s/Cupom gerada não autorizada"
                endif
                if SF2->F2_FIMP $ "D"
                    aNfTemp[aScan(aT49CpNfO,"F2_MENNOTA")] := "Nfe s/Cupom Denegada"
                endif
            endif
        endif
    else
        lNotHasNFCup := .T.
        aNfTemp[aScan(aT49CpNfO,"LEG")] := "BR_VERMELHO"
        aNfTemp[aScan(aT49CpNfO,"F2_MENNOTA")] := "Nfe s/Cupom não gerada"
    endif

Return

Static Function RefreshNotasFat()

    oGridNfOri:aCols := {}
    oGridNfOri:aCols := oGridFat:aCols[oGridFat:nAt][len(aT49CpFat)+1]

    if empty(oGridNfOri:aCols)
        aadd(oGridNfOri:aCols, U_MontaDados("SF2", aT49CpNfO, .T.,,.T.))
    endif

    oGridNfOri:oBrowse:Refresh()
    oGridNfOri:GoTop()

Return

Static Function DoAction(nOpc)
    if nOpc == 1
        FWMsgRun(,{|oSay| GerarNFe(oSay) },'Aguarde','Iniciando processamento...')
    elseif nOpc == 2
        FWMsgRun(,{|oSay| EstornarNFe(oSay) },'Aguarde','Iniciando processamento...')
    elseif nOpc == 3
        FWMsgRun(,{|oSay| TransmitirNFe(oSay) },'Aguarde','Iniciando processamento...')
    elseif nOpc == 4
        FWMsgRun(,{|oSay| LoadFatura(oSay,,.T.) },'Aguarde','Iniciando processamento...')
    endif
Return

Static Function GerarNFe(oSay)

    Local lHasNFCePend := .F.
    Local nPosAux := 0
    Local aNotasGerar := {}
    Local nX := 0
    Local nY := 0
    Local nPosNf := len(aT49CpFat)+1
    Local nPosMark := aScan(aT49CpNfO,"MARK")
    Local nPosLegend := aScan(aT49CpNfO,"LEG")
    Local nPosFilial := aScan(aT49CpNfO,"F2_FILIAL")
    Local nPosDoc := aScan(aT49CpNfO,"F2_DOC")
    Local nPosSerie := aScan(aT49CpNfO,"F2_SERIE")
    Local nPosFatura := aScan(aT49CpFat,"E1_NUM")
    Local nPosCliente := aScan(aT49CpFat,"E1_CLIENTE")
    Local nPosLoja := aScan(aT49CpFat,"E1_LOJA")
    Local nPosLegFat := aScan(aT49CpFat,"LEG")
    Local cBkpFil := cFilAnt
    Local lNota := .T. //Informa se é geração ou estorno da NF (T=Gerar, F=Estornar)
    Local nNfeGeradas := 0
    Local nQtdNfe := 0
    Local lIndiviual := .F.
    Local cMsgAdic := ""
    Local aRetParam := {}
	Local aParamBox := {}

    aAdd(aParamBox,{2,"Tipo NF s/ Cupom","1",{"1=Aglutinado","2=Individual"},70,"",.F.})
    aAdd(aParamBox,{11,"Mensagem p/ Nota","",".T.",".T.",.F.}) 

    If ParamBox(aParamBox,"Gerar NFe s/ Cupom - Configurações",@aRetParam,,,,,,,,.f.) // Parametro
        lIndiviual := aRetParam[1] == "2"
        cMsgAdic := StrTran(Alltrim(aRetParam[2]),CRLF," / ")
    else
        Return
    endif

    //verifico se marcou alguma nota fiscal
    oSay:SetText("Verificando NFCe marcadas...")
    oSay:Refresh()
    for nX := 1 to len(oGridFat:aCols)
        if oGridFat:aCols[nX][nPosLegFat] <> "BR_VERMELHO" //se nao tem nfce sem nfe
            LOOP
        endif

        for nY := 1 to len(oGridFat:aCols[nX][nPosNf])
            if oGridFat:aCols[nX][nPosNf][nY][nPosLegend] == "BR_VERMELHO" //somente o que nao gerou ainda
                lHasNFCePend := .T.

                if oGridFat:aCols[nX][nPosNf][nY][nPosMark] == "LBOK"
                    nPosAux := aScan(aNotasGerar, {|x| x[1] == nX .AND. x[2] == oGridFat:aCols[nX][nPosNf][nY][nPosFilial]})
                    if lIndiviual .OR. nPosAux == 0
                        aadd(aNotasGerar, {nX, oGridFat:aCols[nX][nPosNf][nY][nPosFilial], {}, 0/*recno da SF2 gerada*/})
                        nPosAux := len(aNotasGerar)
                    endif

                    AAdd(aNotasGerar[nPosAux][3],{ ;
                            oGridFat:aCols[nX][nPosNf][nY][nPosDoc],; //F2_DOC
                            oGridFat:aCols[nX][nPosNf][nY][nPosSerie],; //F2_SERIE
                            oGridFat:aCols[nX][nPosCliente],; //F2_CLIENTE
                            oGridFat:aCols[nX][nPosLoja]}) //F2_LOJA
                endif
            endif
        next nY
    next nX

    if empty(aNotasGerar)
        if !lHasNFCePend 
            MsgInfo("Não há NFCe pendentes de gerar NFe!")
        else
            if MsgYesNo("Nenhuma NFCe selecionada para gerar NFe! Deseja gerar de todas as faturas que possuem NFCe sem NFe?","Atenção")
                
                oSay:SetText("Verificando NFCe sem NFe...")
                oSay:Refresh()
                for nX := 1 to len(oGridFat:aCols)
                    if oGridFat:aCols[nX][nPosLegFat] <> "BR_VERMELHO" //se nao tem nfce sem nfe
                        LOOP
                    endif

                    for nY := 1 to len(oGridFat:aCols[nX][nPosNf])
                        if oGridFat:aCols[nX][nPosNf][nY][nPosLegend] == "BR_VERMELHO" //somente o que nao gerou ainda
                            nPosAux := aScan(aNotasGerar, {|x| x[1] == nX .AND. x[2] == oGridFat:aCols[nX][nPosNf][nY][nPosFilial]})
                            if lIndiviual .OR. nPosAux == 0
                                aadd(aNotasGerar, {nX, oGridFat:aCols[nX][nPosNf][nY][nPosFilial], {}, 0/*recno da SF2 gerada*/})
                                nPosAux := len(aNotasGerar)
                            endif

                            oGridFat:aCols[nX][nPosNf][nY][nPosMark] := "LBOK"

                            AAdd(aNotasGerar[nPosAux][3],{ ;
                                    oGridFat:aCols[nX][nPosNf][nY][nPosDoc],; //F2_DOC
                                    oGridFat:aCols[nX][nPosNf][nY][nPosSerie],; //F2_SERIE
                                    oGridFat:aCols[nX][nPosCliente],; //F2_CLIENTE
                                    oGridFat:aCols[nX][nPosLoja]}) //F2_LOJA
                        endif
                    next nY
                next nX

            endif
        endif
    endif

    if !empty(aNotasGerar)
        MDL->(DbSetOrder(2)) // MDL_FILIAL+MDL_CUPOM+MDL_SERCUP+MDL_NFCUP+MDL_SERIE
        nQtdNfe := len(aNotasGerar)
        for nX := 1 to nQtdNfe
            
            cFilAnt := aNotasGerar[nX][2]
            lMsErroAuto := .F.

            oSay:SetText("Gerando NFe da fatura "+oGridFat:aCols[aNotasGerar[nX][1]][nPosFatura]+"... ("+cValToChar(nX)+"/"+cValToChar(nQtdNfe)+")")
            oSay:Refresh()
            ProcessMessages()

            SetMvValue("LJR131", "MV_PAR10", "")
            SetMvValue("LJR131", "MV_PAR11", "")
            MV_PAR10 := ""
            MV_PAR11 := ""

            //Chama a rotina de nota sobre cupom
            LojR130(aNotasGerar[nX][3],lNota,aNotasGerar[nX][3][1][3],aNotasGerar[nX][3][1][4])

            If lMsErroAuto 
                //MostraErro()
            EndIf
            
            if MDL->(DbSeek(cFilAnt+aNotasGerar[nX][3][1][1]+aNotasGerar[nX][3][1][2])) //verifico se o primeiro cupom gerou nfe e posiciono na nota
                nNfeGeradas++

                SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
                If SF2->( DbSeek( MDL->MDL_FILIAL + MDL->MDL_NFCUP + MDL->MDL_SERIE + aNotasGerar[nX][3][1][3] + aNotasGerar[nX][3][1][4]) )
                    aNotasGerar[nX][4] := SF2->(Recno())
                    RecLock("SF2",.F.)
                    SF2->F2_XNFFATU := "S"  
                    SF2->F2_TPFRETE := "S" // Acrescentado por Wellington Gonçalves dia 05/01/2015. Na nota sobre cupom não deve gerar frete
                    SF2->F2_XMSGADI := cMsgAdic //Mensagem adicional no DANFE
                    SF2->(MsUnlock())
                EndIf
            endif

        next nX

        if nNfeGeradas > 0
            LoadFatura(oSay) //atualiza a tela
            
            if MsgYesNo("Foram geradas "+cValToChar(nNfeGeradas)+" NFe(s) com sucesso! "+CRLF+CRLF+"Deseja transmiti-las agora?","Atenção")
                TransmitirNFe(oSay, .T.)
            endif
            
        else
            MsgInfo("Nenhuma NFe gerada!")
        endif

    endif

    cFilAnt := cBkpFil

Return

Static Functio EstornarNFe(oSay)

    Local lHasNFeCup := .F.
    Local nTentativas := 0
    Local cRetorno := ""
    Local nPosAux := 0
    Local aNfEstorno := {}
    Local nX := 0
    Local nY := 0
    Local nPosNf := len(aT49CpFat)+1
    Local nPosMark := aScan(aT49CpNfO,"MARK")
    Local nPosFilial := aScan(aT49CpNfO,"F2_FILIAL")
    Local nPosDoc := aScan(aT49CpNfO,"MDL_NFCUP")
    Local nPosSerie := aScan(aT49CpNfO,"MDL_SERIE")
    Local nPosCliente := aScan(aT49CpFat,"E1_CLIENTE")
    Local nPosLoja := aScan(aT49CpFat,"E1_LOJA")
    Local cBkpFil := cFilAnt
    Local nQtdNfe := 0
    Local nNfeEstorn := 0

    //verifico se marcou alguma nota fiscal
    oSay:SetText("Verificando NFe marcadas...")
    oSay:Refresh()
    for nX := 1 to len(oGridFat:aCols)
        for nY := 1 to len(oGridFat:aCols[nX][nPosNf])
            if !empty(oGridFat:aCols[nX][nPosNf][nY][nPosDoc]) //somente o que tem nfe s/cupom
                lHasNFeCup := .T.

                if oGridFat:aCols[nX][nPosNf][nY][nPosMark] == "LBOK"
                    nPosAux := aScan(aNfEstorno, {|x| x[1] == nX .AND. x[2] == oGridFat:aCols[nX][nPosNf][nY][nPosFilial]})
                    if nPosAux == 0
                        aadd(aNfEstorno, {nX, oGridFat:aCols[nX][nPosNf][nY][nPosFilial], {}})
                        nPosAux := len(aNfEstorno)
                    endif

                    if aScan(aNfEstorno[nPosAux][3], {|aNF| aNf[1] == oGridFat:aCols[nX][nPosNf][nY][nPosDoc] .AND. aNf[2] == oGridFat:aCols[nX][nPosNf][nY][nPosSerie]}) == 0

                        SF2->(DbSetOrder(1))//"F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO"
                        If SF2->( DbSeek(oGridFat:aCols[nX][nPosNf][nY][nPosFilial] + oGridFat:aCols[nX][nPosNf][nY][nPosDoc] + oGridFat:aCols[nX][nPosNf][nY][nPosSerie] ) )
                            
                            if !U_TR042VLP() //valida o prazo para cancelamento
                                Return
                            endif

                            AAdd(aNfEstorno[nPosAux][3],{ ;
                                oGridFat:aCols[nX][nPosNf][nY][nPosDoc],; //F2_DOC
                                oGridFat:aCols[nX][nPosNf][nY][nPosSerie],; //F2_SERIE
                                oGridFat:aCols[nX][nPosCliente],; //F2_CLIENTE
                                oGridFat:aCols[nX][nPosLoja]}) //F2_LOJA
                            
                        Else
                            MsgInfo("Nota fiscal "+oGridFat:aCols[nX][nPosNf][nY][nPosDoc]+"/"+oGridFat:aCols[nX][nPosNf][nY][nPosSerie]+" não encontrada para estorno!","Atenção")
                            Return
                        Endif
                        
                    endif
                endif
            endif
        next nY
    next nX

    if empty(aNfEstorno)
        if !lHasNFeCup 
            MsgInfo("Não há NFe s/Cupom para estornar!")
        else
            MsgInfo("Nenhuma NFe s/Cupom selecionada para estornar!","Atenção")
        endif
    else
        if MsgYesNo("Confirma estorno das notas fiscais marcadas?")
            
            oSay:SetText("Estornando NFe s/Cupom selecionadas...")
            oSay:Refresh()

            //chama rotina de estorno em JOB
            StartJOB("U_TRE049ES",GetEnvServer(), .T./*lWait*/, cEmpAnt, aNfEstorno)

            nQtdNfe := len(aNfEstorno)
            for nX := 1 to nQtdNfe
                for nY := 1 to len(aNfEstorno[nX][3])
                    MDL->(DbSetOrder(2)) // MDL_FILIAL+MDL_CUPOM+MDL_SERCUP+MDL_NFCUP+MDL_SERIE
                    if !MDL->(DbSeek(aNfEstorno[nX][2]+aNfEstorno[nX][3][nY][1]+aNfEstorno[nX][3][nY][2])) 
                        nNfeEstorn++
                        aNfEstorno[nX][3][nY][4] := "OK"
                    endif
                next nY
            next nX

            if nNfeEstorn > 0
                //transmitir cancelamento dessas NF
                oSay:SetText("Transmitindo o cancelamento/inutilização das NF estornadas...")
                oSay:Refresh()
                for nX := 1 to nQtdNfe
                    for nY := 1 to len(aNfEstorno[nX][3])
                        if aNfEstorno[nX][3][nY][4] == "OK"
                            TransNFe(aNfEstorno[nX][2], aNfEstorno[nX][3][nY][1], aNfEstorno[nX][3][nY][2])        
                        endif
                    next nY
                next nX

                While nTentativas < 10 
                    nTentativas++
                    oSay:SetText("Monitorando o cancelamento/inutilização das NF estornadas...("+cValToChar(nTentativas)+")")
                    oSay:Refresh()
                    Sleep(3000) //aguarda alguns segundos para chamar o monitor de notas

                    for nX := 1 to nQtdNfe
                        for nY := 1 to len(aNfEstorno[nX][3])
                            if aNfEstorno[nX][3][nY][4] == "OK"
                                cRetorno := MonitNFe(aNfEstorno[nX][2], aNfEstorno[nX][3][nY][1], aNfEstorno[nX][3][nY][2])        
                                if !empty(cRetorno)
                                    aNfEstorno[nX][3][nY][4] := cRetorno
                                endif
                            endif
                        next nY
                    next nX

                    if aScan(aNfEstorno, {|aNfs|  aScan(aNfs[3],{|aNf| aNf[4]=="OK"})>0   }) == 0
                        EXIT
                    endif
                enddo

                //MEMOWRITE( "C:\Temp\TRETE049_estorn.txt", "nTentativas: " + cValToChar(nTentativas) + CRLF + VarInfo("aNfEstorno",aNfEstorno) )

                LoadFatura(oSay,,.T.)//atualiza a tela, olhando TSS
            else
                MsgAlert("Nenhuma NFe estornada!","Atenção")
            endif
            
        endif
    endif

    cFilAnt := cBkpFil

Return

//Processa o estorno de notas fiscais em JOB, pois há um bug no fonte LOJR130
//o BUG: Após estornar uma nota, ao tentar gerar qq outra, o sistema não gera mais por conta
// da variavel Static lEstorno que não é resetada
User Function TRE049ES(cEmp, aNfEstorno)

    Local nX
    Local nQtdNfe := len(aNfEstorno)
    Local lNota := .F. //Informa se é geração ou estorno da NF (T=Gerar, F=Estornar)

    if nQtdNfe == 0
        Return
    endif

    RPCSetType(3)		
    RPCSetEnv( cEmp, aNfEstorno[1][2], Nil, Nil,"FRT")

    for nX := 1 to nQtdNfe
        
        cFilAnt := aNfEstorno[nX][2]
        lMsErroAuto := .F.

        SetMvValue("LJR131", "MV_PAR10", "")
        SetMvValue("LJR131", "MV_PAR11", "")
        MV_PAR10 := ""
        MV_PAR11 := ""

        //Chama a rotina de nota sobre cupom
        LojR130(aNfEstorno[nX][3], lNota, aNfEstorno[nX][3][1][3], aNfEstorno[nX][3][1][4])

        If lMsErroAuto 
            //MostraErro()
        EndIf
        
    next nX

    RPCClearEnv()

Return

Static aCodEnt := {} //irá guardar os códigos das entidades para evitar chamadas desnecessárias

Static Function TransmitirNFe(oSay, lAuto)

    Local lHasNFeCup := .F.
    Local nPosAux := 0
    Local aNfTransm := {}
    Local nX := 0
    Local nY := 0
    Local nPosNf := len(aT49CpFat)+1
    Local nPosMark := aScan(aT49CpNfO,"MARK")
    Local nPosFilial := aScan(aT49CpNfO,"F2_FILIAL")
    Local nPosDoc := aScan(aT49CpNfO,"MDL_NFCUP")
    Local nPosSerie := aScan(aT49CpNfO,"MDL_SERIE")
    Local nPosMsg := aScan(aT49CpNfO,"F2_MENNOTA")
    Local nQtdNfe := 0
    Local cRetorno := ""
    Local nTentativas := 0
    Default lAuto := .F.

    //verifico se marcou alguma nota fiscal
    oSay:SetText("Verificando NFe marcadas...")
    oSay:Refresh()
    for nX := 1 to len(oGridFat:aCols)
        for nY := 1 to len(oGridFat:aCols[nX][nPosNf])
            if !empty(oGridFat:aCols[nX][nPosNf][nY][nPosDoc]) //somente o que tem nfe s/cupom
                lHasNFeCup := .T.

                if oGridFat:aCols[nX][nPosNf][nY][nPosMark] == "LBOK"
                    if aScan(aNfTransm, {|aNF| aNf[1] == oGridFat:aCols[nX][nPosNf][nY][nPosFilial] .AND. aNF[2] == oGridFat:aCols[nX][nPosNf][nY][nPosDoc] .AND. aNf[3] == oGridFat:aCols[nX][nPosNf][nY][nPosSerie]}) == 0

                        SF2->(DbSetOrder(1))//"F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO"
                        If SF2->( DbSeek(oGridFat:aCols[nX][nPosNf][nY][nPosFilial] + oGridFat:aCols[nX][nPosNf][nY][nPosDoc] + oGridFat:aCols[nX][nPosNf][nY][nPosSerie] ) )

                            if !(SF2->F2_FIMP $ "TS") //T=Transmitida, S=Autorizada
                                AAdd(aNfTransm, { ;
                                    oGridFat:aCols[nX][nPosNf][nY][nPosFilial],; //F2_FILIAL
                                    oGridFat:aCols[nX][nPosNf][nY][nPosDoc],; //F2_DOC
                                    oGridFat:aCols[nX][nPosNf][nY][nPosSerie],; //F2_SERIE
                                    nX, ; //posição da nota no grid
                                    SF2->F2_FIMP, ; //guarda retorno do monitoramento
                                    SF2->(Recno()) ,; //recno da nota
                                    }) 
                            endif
                            
                        Else
                            MsgInfo("Nota fiscal "+oGridFat:aCols[nX][nPosNf][nY][nPosDoc]+"/"+oGridFat:aCols[nX][nPosNf][nY][nPosSerie]+" não encontrada para transmissão !","Atenção")
                            Return
                        Endif
                        
                    endif
                endif
            endif
        next nY
    next nX

    if empty(aNfTransm)
        if !lHasNFeCup 
            MsgInfo("Não há NFe s/Cupom para transmitir!")
        else
            MsgInfo("Nenhuma NFe s/Cupom selecionada para transmitir!","Atenção")
        endif
    else
        if lAuto .OR. MsgYesNo("Confirma Transmissão das notas fiscais marcadas?")
            
            nQtdNfe := len(aNfTransm)
            for nPosAux := 1 to nQtdNfe
                
                oSay:SetText("Transmitindo NFe "+aNfTransm[nPosAux][2]+"/"+aNfTransm[nPosAux][3]+"... ("+cValToChar(nPosAux)+"/"+cValToChar(nQtdNfe)+")")
                oSay:Refresh()

                TransNFe(aNfTransm[nPosAux][1], aNfTransm[nPosAux][2], aNfTransm[nPosAux][3])

                SF2->(DbGoTo(aNfTransm[nPosAux][6]))
                aNfTransm[nPosAux][5] := SF2->F2_FIMP //se conseguiu transmitir F2_FIMP estará com T
                cRetorno := iif(SF2->F2_FIMP=="T","NFe transmitida com sucesso. Aguardando autorização!","Não foi possível transmitir a NFe!")

                nX := aNfTransm[nPosAux][4]
                for nY := 1 to len(oGridFat:aCols[nX][nPosNf])
                    if oGridFat:aCols[nX][nPosNf][nY][nPosFilial] == aNfTransm[nPosAux][1] .AND. oGridFat:aCols[nX][nPosNf][nY][nPosDoc] == aNfTransm[nPosAux][2] .AND. oGridFat:aCols[nX][nPosNf][nY][nPosSerie] == aNfTransm[nPosAux][3]
                        oGridFat:aCols[nX][nPosNf][nY][nPosMsg] := cRetorno
                    endif
                next nY

            next nPosAux

            oGridNfOri:oBrowse:Refresh()

            While nTentativas < 10 
                nTentativas++
                oSay:SetText("Monitorando as NFe transmitidas...("+cValToChar(nTentativas)+")")
                oSay:Refresh()
                Sleep(3000) //aguarda alguns segundos para chamar o monitor de notas

                for nPosAux := 1 to nQtdNfe
                    if aNfTransm[nPosAux][5] == "T" //transmitido
                        cRetorno := MonitNFe(aNfTransm[nPosAux][1], aNfTransm[nPosAux][2], aNfTransm[nPosAux][3])        
                        if !empty(cRetorno)
                            aNfTransm[nPosAux][5] := cRetorno
                        endif
                    endif
                next nPosAux

                if aScan(aNfTransm, {|aNf|  aNf[5]=="T" }) == 0
                    EXIT
                endif
            enddo

            //MEMOWRITE( "C:\Temp\TRETE049_trans.txt", "nTentativas: " + cValToChar(nTentativas) + CRLF + VarInfo("aNfTransm",aNfTransm) )

            LoadFatura(oSay,,.T.)//atualiza a tela, olhando TSS
            
        endif
    endif

    cFilAnt := cBkpFil

    oGridFat:oBrowse:Refresh()
    oGridNfOri:oBrowse:Refresh()

Return

//executa a transmissão da NFe
Static Function TransNFe(cFil, cDoc, cSerie)

	Local cAmbiente		:= ""
	Local cModalidade	:= ""
	Local cVersao		:= ""
	Local lEnd			:= .F.
	Local aArea			:= GetArea()
	Local aSF2aArea		:= SF2->( GetArea() )
	Local lAux  		:= .T.
    Local cBkpFil       := cFilAnt
    Local aSM0Area      := SM0->(GetArea())
    Local cModelo := "55"
    Local cURLNFe := ""
    Local cIdEnt := ""
    Local cRetorno      := ""

    cFilAnt := cFil

    if (nPosAux := aScan(aCodEnt, {|aFil| aFil[1] == cFilAnt})) > 0
        cURLNFe := aCodEnt[nPosAux][3]
        cIdEnt := aCodEnt[nPosAux][2]
        SM0->(DbGoTo(aCodEnt[nPosAux][4]))
    else
        DbSelectArea("SM0")
        SM0->(DbSetOrder(1))
        SM0->(DbSeek(cEmpAnt+cFilAnt))

        cURLNFe := AllTrim( GetMV("MV_SPEDURL") )
        cIdEnt := LjTSSIDENT( cModelo ,, .T.)

        aadd(aCodEnt, {cFilAnt, cIdEnt, cURLNFe, SM0->(Recno())})
    endif

	Private bFiltraBrw := {||}	//usado por compatibilidade por causa do fonte SPEDNFE.PRX

	MV_PAR01 := cSerie
	MV_PAR02 := cDoc
	MV_PAR03 := cDoc
	
	If !Empty(cIDEnt)

		//------------------------------------
		// Obtem os parametros do servidor TSS
		//------------------------------------
		//carregamos o array estatico com os parametros do TSS
		lAux := &("StaticCall(LOJNFCE, LjCfgTSS, '55')[1]")
		If lAux 
			cAmbiente	:= &("StaticCall(LOJNFCE, LjCfgTSS, '55', 'AMB')[2]")
			cModalidade := &("StaticCall(LOJNFCE, LjCfgTSS, '55', 'MOD')[2]")
			cVersao		:= &("StaticCall(LOJNFCE, LjCfgTSS, '55', 'VER')[2]")

			// Realiza a transmissão da NF-e
			cRetorno := SpedNFeTrf(	"SF2"	, cSerie       , cDoc        , cDoc        ,;
									cIDEnt	, cAmbiente	   , cModalidade , cVersao	   ,;
									@lEnd	, .F.		   , .F. )
			/*
			3 ULTIMOS PARAMETROS:
				lEnd - parametro não utilizado no SPEDNFeTrf
				lCte
				lAuto
			*/
		Else
			cRetorno += "Não foi possível obter o valor dos parâmetros do TSS."
	    EndIf
    Else
        cRetorno += "Não foi possível obter o Código da Entidade (IDENT) do servidor TSS."
	EndIf

    cFilAnt := cBkpFil

    RestArea(aSF2aArea)
    RestArea(aSM0Area)
    RestArea(aArea)

Return cRetorno


Static Function MonitNFe(cFil, cDoc, cSerie)

    Local nPosAux := 0
    Local cRet := ""
    Local cError := ""
    Local cModelo := "55"
    Local cURLNFe := ""
    Local cIdEnt := ""
    Local aInfMonNFe := {}
    Local cBkpFil := cFilAnt
    Local aArea := GetArea()
    Local aSM0Area := SM0->(GetArea())
    Local aAreaSF2 := SF2->(GetArea())

    cFilAnt := cFil

    if (nPosAux := aScan(aCodEnt, {|aFil| aFil[1] == cFilAnt})) > 0
        cURLNFe := aCodEnt[nPosAux][3]
        cIdEnt := aCodEnt[nPosAux][2]
        SM0->(DbGoTo(aCodEnt[nPosAux][4]))
    else
        DbSelectArea("SM0")
        SM0->(DbSetOrder(1))
        SM0->(DbSeek(cEmpAnt+cFilAnt))

        cURLNFe := AllTrim( GetMV("MV_SPEDURL") )
        cIdEnt := LjTSSIDENT( cModelo ,, .T.)

        aadd(aCodEnt, {cFilAnt, cIdEnt, cURLNFe, SM0->(Recno())})
    endif

    If !Empty(cIDEnt)

        aInfMonNFe := ProcMonitorDoc(   cIdEnt,;
                                        cURLNFe,;
                                        {cSerie,cDoc,cDoc},;
                                        1 /*nTpMonitor*/,;
                                        cModelo,;
                                        .F. /*lCte*/,;
                                        @cError)

        if len(aInfMonNFe)>0 .AND. !Empty(aInfMonNFe[1][5])
            cRet := aInfMonNFe[1][5] + "-" + aInfMonNFe[1][6]
        endif

    endif

    cFilAnt := cBkpFil

    RestArea(aAreaSF2)
    RestArea(aSM0Area)
    RestArea(aArea)

Return cRet

