#include 'totvs.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETP033
Tratamento complementar
O ponto de entrada F190BROW é executado antes da Mbrowse, pre validando os dados a serem exibidos.

@author Totvs GO
@since 28/08/2020
@version 1.0
@return Retorna URET(nulo)

@type function
/*/
User Function TRETP033()
    aadd(aRotina, {"Liber Cheque Lote", "U_UFA190LI()", 0, 2})
Return

/*/{Protheus.doc} UFA190LI
Libera Cheque em Lote (seleção de vários cheques)

@author  author
@since   date
@version version
/*/
User Function UFA190LI()

    Local nOpca     := 3    // Deve ser 3 para, caso seja teclado ESC, retorna sem fazer nada
    Local aCores    := {}
    Local oQtdTit   := 0
    Local oValor    := 0
    Local oDlg1
    Local aMvPars := {}
    Local nX := 0

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
    //Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return
    EndIf

    Private cAlias := GetNextAlias()
    Private nQtdTit   := 0 // quantidade de cheques,mostrado no rodape do browse
    Private nValor    := 0 // valor total dos cheques,mostrado no rodape do browse
    Private lInverte, cMarca

    cMarca := GetMark(.T.)

    aCores := {}
    aAdd(aCores, {"EF_LIBER = 'S'", "BR_VERDE"}) //já gerou financeiro
    aAdd(aCores, {"EF_LIBER = 'N'", "BR_VERMELHO"}) //pendênte a geração financeira

    //backup dos mv_par
    for nX:=1 to 10 // baço backup de 10, pois só utilizo 10 (até mv_par10)
        aadd(aMvPars,{'mv_par'+StrZero(nX,2),&('mv_par'+StrZero(nX,2))})
    next nX

    Pergunte("FIN540", .T.)

    cCondicao := "EF_FILIAL  == '"+xFilial("SEF") + "' .And. "
    cCondicao += "EF_BANCO   >= '" + mv_par01 + "' .And. "
    cCondicao += "EF_BANCO   <= '" + mv_par02 + "' .And. "
    cCondicao += "EF_AGENCIA >= '" + mv_par03 + "' .And. "
    cCondicao += "EF_AGENCIA <= '" + mv_par04 + "' .And. "
    cCondicao += "EF_CONTA   >= '" + mv_par05 + "' .And. "
    cCondicao += "EF_CONTA   <= '" + mv_par06 + "' .And. "
    cCondicao += "EF_NUM     >= '" + mv_par07 + "' .And. "
    cCondicao += "EF_NUM     <= '" + mv_par08 + "' .And. "
    cCondicao += "DTOS(EF_DATA) >= '" + DTOS(mv_par09) + "' .And. "
    cCondicao += "DTOS(EF_DATA) <= '" + DTOS(mv_par10) + "' .And. "
    //cCondicao += "EF_LIBER = 'N' .And. " //não gerado financeiro
    cCondicao += "EF_ORIGEM  = 'FINA390AVU' " //cheque troco -> cheque avulso

    // limpo os filtros da SEF
    SEF->(DbClearFilter())

    // executo o filtro na SEF
    bCondicao := "{|| " + cCondicao + " }"
    SEF->(DbSetFilter(&bCondicao,cCondicao))

    // vou para a primeira linha
    SEF->(DbGoTop())

    aCampos := {}
    aFields := {}
    AADD(aCampos,{"EF_OK","","  ",""})
    AADD(aFields,{"EF_OK","C",2,0})

    aSX3SEF := FWSX3Util():GetAllFields("SEF",.F./*lVirtual*/)
    If !Empty(aSX3SEF)
        For nX:=1 to len(aSX3SEF)
            If AllTrim(aSX3SEF[nX]) <> "EF_OK"
                AADD(aCampos,{aSX3SEF[nX],"",FWX3Titulo(aSX3SEF[nX]),GetSx3Cache(aSX3SEF[nX],"X3_PICTURE")})
                AADD(aFields,{aSX3SEF[nX],GetSx3Cache(aSX3SEF[nX],"X3_TIPO"),GetSx3Cache(aSX3SEF[nX],"X3_TAMANHO"),GetSx3Cache(aSX3SEF[nX],"X3_DECIMAL")})
            EndIf
        Next nX
    EndIf

    //cria a tabela temporaria
    oTempTable := FWTemporaryTable():New(cAlias)
    oTempTable:SetFields(aFields)
    oTempTable:AddIndex("01", {"EF_FILIAL", "EF_BANCO", "EF_AGENCIA", "EF_CONTA", "EF_NUM"}) //EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM
    oTempTable:Create()

    While SEF->(!Eof())
        (cAlias)->(RecLock(cAlias,.T.))
        For nX:=1 to Len(aFields)
            If !( aFields[nX][1] $ "EF_OK")
                &("(cAlias)->"+aFields[nX][1]) := &("SEF->"+(aFields[nX][1]))
            EndIf
        Next nX
        (cAlias)->(MsUnlock())
        SEF->(DbSkip())
    EndDo

    // limpo os filtros da SEF
    SEF->(DbClearFilter())

    (cAlias)->(DBSetOrder(1)) //EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM
    (cAlias)->(DbGoTop())

    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
    //³ Faz o calculo automatico de dimensoes de objetos     ³
    //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    aSize := MSADVSIZE()
    DEFINE MSDIALOG oDlg1 TITLE  "Liberação de Cheques" From aSize[7],0 To aSize[6],aSize[5] OF oMainWnd PIXEL
    oDlg1:lMaximized := .T.

    oPanel := TPanel():New(0,0,'',oDlg1,, .T., .T.,, ,20,20,.T.,.T. )
    oPanel:Align := CONTROL_ALIGN_TOP

    //@ 003 , 005  SAY "Totalizadores: "   FONT oDlg1:oFont PIXEL OF oPanel
    //@ 003 , 005  SAY "Banco: "  + cBanco190   FONT oDlg1:oFont PIXEL OF oPanel
    //@ 003 , 060  Say "Agência: "  + cagencia190 FONT oDlg1:oFont PIXEL OF oPanel
    //@ 003 , 115  SAY "Conta: "  + cConta190   FONT oDlg1:oFont PIXEL OF oPanel
    //@ 003 , 180  SAY "N° Cheque: "  + SubStr(cCheque190,1,15) FONT oDlg1:oFont PIXEL OF oPanel

    @ 003, 005 BITMAP o1 RESNAME "BR_VERDE" SIZE 16,16 NOBORDER PIXEL OF oPanel
    @ 003, 015 SAY "Cheque Liberado" FONT oDlg1:oFont PIXEL OF oPanel
    @ 003, 115 BITMAP o2 RESNAME "BR_VERMELHO" SIZE 16,16 NOBORDER PIXEL OF oPanel
    @ 003, 125 SAY "Cheque Não Liberado" FONT oDlg1:oFont PIXEL OF oPanel

    @ 012 , 005  Say "N° Cheques Selecionados: "   FONT oDlg1:oFont PIXEL OF oPanel
    @ 012 , 075  Say oQtdTit VAR nQtdTit Picture "999999"	FONT oDlg1:oFont SIZE 30,10 PIXEL OF oPanel
    @ 012 , 115  Say "Valor Total: " FONT oDlg1:oFont PIXEL OF oPanel
    @ 012 , 170  Say oValor VAR nValor Picture PesqPict("SEF","EF_VALOR") FONT oDlg1:oFont PIXEL OF oPanel

    oMark := MsSelect():New(cAlias,"EF_OK","",aCampos,@lInverte,@cMarca,{45,oDlg1:nLeft,oDlg1:nBottom,oDlg1:nRight},,,,,aCores)
    oMark:bMark := {|| Fa190Exibe(@nValor,@nQtdTit,cMarca,oValor,oQtdTit)}
    oMark:oBrowse:lhasMark = .T.
    oMark:oBrowse:lCanAllmark := .T.
    oMark:bAval	:= {|| Fa190bAval(cMarca,oValor,oQtdTit)}
    oMark:oBrowse:bAllMark := {|| FA190Inverte(cMarca,oValor,oQtdTit)}
    oMark:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

    ACTIVATE MSDIALOG oDlg1 ON INIT EnchoiceBar(oDlg1, {||nOpca:=1, oDlg1:End()}, {||nOpca:=2, oDlg1:End()}) CENTERED

    // restaura os parametros
    for nX:=1 to Len(aMvPars)
        &(aMvPars[nX][1]) := aMvPars[nX][2]
    next nX

    If nOpca = 1
        SEF->(DbSetOrder(1)) //EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM
        (cAlias)->(DbGoTop())
        While (cAlias)->(!Eof())
            If (cAlias)->EF_OK == cMarca
                If SEF->(DbSeek((cAlias)->(EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM)))
                    fA190Lib() //FINA190 -> fA190Lib "Liberacao do cheque -> atualiza o saldo bancario SE5"
                EndIf
            EndIf
            (cAlias)->(DbSkip())
        EndDo
    EndIf

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf

    oTempTable:Delete()

Return

/*/
    ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
    ±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
    ±±³Fun‡…o	 ³Fa190bAval ³ Autor ³ Claudio D. de Souza  ³ Data ³ 09/11/05 ³±±
    ±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
    ±±³Descri‡…o ³Bloco de marcacoo       			          				  ³±±
    ±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
    ±±³Sintaxe	 ³ Fa190bAval()		  										  ³±±
    ±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
    ±±³ Uso		 ³ FINA190													  ³±±
    ±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
    ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
    ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function Fa190bAval(cMarca,oValor,oQtdTit)

    Local lRet 		:= .T.

// Verifica se o registro nao esta sendo utilizado em outro terminal
    If (cAlias)->(MsRLock())
        FA190Inverte(cMarca,oValor,oQtdTit,.F.)
    Else
        IW_MsgBox("Este cheque está sendo utilizado em outro terminal, não pode ser utilizado.","Atenção","STOP")
        lRet := .F.
    Endif

    oMark:oBrowse:Refresh(.T.)

Return lRet

/*/
    ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
    ±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
    ±±³Fun‡…o    ³FA190Inverte³ Autor ³ Wagner Xavier       ³ Data ³ 07/11/95 ³±±
    ±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
    ±±³Descri‡…o ³ Marca e Desmarca Titulos, invertendo a marca‡†o existente  ³±±
    ±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
    ±±³Sintaxe   ³ Fa190Inverte()                                             ³±±
    ±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
    ±±³ Uso      ³ FINA190                                                    ³±±
    ±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
    ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
    ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function Fa190Inverte(cMarca,oValor,oQtda,lTodos)

    Local cChave := (cAlias)->(EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM) //backup do que esta posicionado
    Local nAscan

    Default lTodos := .T.

    If lTodos
        dbSelectArea(cAlias)
        (cAlias)->(DbGoTop())
    EndIf

    While !lTodos .OR. (cAlias)->(!Eof())

        If (cAlias)->(MsRLock())
            RecLock(cAlias)
            IF (cAlias)->EF_OK == cMarca
                (cAlias)->EF_OK := "  "
                nValor -= (cAlias)->EF_VALOR
                nQtdTit--
            Else
                If (cAlias)->EF_LIBER = 'N' //so marca o cheque que pode ser liberado
                    (cAlias)->EF_OK := cMarca
                    nValor += (cAlias)->EF_VALOR
                    nQtdTit++
                Endif
            Endif
            (cAlias)->(MsUnlock())
        Endif

        If lTodos
            (cAlias)->(DbSkip())
        Else
            Exit //sai do While
        Endif

    EndDo

    (cAlias)->(DbSeek(cChave))
    oValor:Refresh()
    oQtda:Refresh()
    oMark:oBrowse:Refresh(.T.)

Return Nil
