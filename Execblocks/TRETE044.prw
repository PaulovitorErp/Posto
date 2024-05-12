#INCLUDE "TOTVS.CH"
#include "protheus.ch"
#include "topconn.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} User Function TRETE044
Envio de Email de Faturas/Boletos/Danfes

@type  Function
@author danilo
@since 02/02/2022
@version 1
@param aFatura, array, {cNumero,cCliFat,cLojaFat,cPref,cParc}
/*/
User Function TRETE044(_cFil, aFat, lFatura, lBoleto, lDanfeXml)
    
    Local lEnvioOK := .T.
    Local nI
    Local aArqAux := {}
    Local cEmails := ""
    Local cFatura := aFat[1][1]+iif(!empty(aFat[1][5]),'-'+aFat[1][5],'')
    Local cNomEmp 	:= Alltrim(SuperGetMv("MV_XNOMEMP",.F.,SM0->M0_FULNAME))
	Local cAssunto	:= SuperGetMv("MV_XMAILAS",.F.,"Fatura ") + cFatura + " - " + cNomEmp
	Local cCc		:= SuperGetMv("MV_XMAILCC",.F.,"")
    Local nTamEmail := TamSX3("A1_EMAIL")[1] + TamSX3("A1_XEMAIL")[1]
    Local lLogMail	:= SuperGetMv("MV_XLGMAIL",.F.,.F.) .AND. ChkFile("U0J")
    
    Private oMsGetArq
    Private oWebChannel := TWebChannel():New()
    Private oWebEngine 
    Private lHtmlShow := .F.
    Private aArqEmail := {}
    Private aArqAnex := {}
    Private cHtml044 := ""

    Static oDlgMail

    Default lFatura := .T.
    Default lBoleto := .T.
    Default lDanfeXml := .T.

    cEmails := Alltrim(Posicione("SA1",1,xFilial("SA1")+aFat[1][2]+aFat[1][3],"A1_EMAIL")) 
    if Empty(cEmails)
        cEmails := Alltrim(Posicione("SA1",1,xFilial("SA1")+aFat[1][2]+aFat[1][3],"A1_XEMAIL"))
    elseif !empty(Posicione("SA1",1,xFilial("SA1")+aFat[1][2]+aFat[1][3],"A1_XEMAIL"))
        cEmails += ";"+Alltrim(Posicione("SA1",1,xFilial("SA1")+aFat[1][2]+aFat[1][3],"A1_XEMAIL"))
    endif

    if len(aFat) > 1 //se varias faturas, deixo o assunto generico
        cAssunto	:= SuperGetMv("MV_XMAILAS",.F.,"Fatura ") + dtoc(dDatabase) + " - " + cNomEmp
    endif

    if !(isBlind()) .OR. !empty(cEmails)
        aArqEmail := GetArqPDF(_cFil, aFat, lFatura, lBoleto, lDanfeXml)

        //if !empty(aArqEmail)
            
            if ExistBlock("UMAILFAT")
                cHtml044 := ExecBlock("UMAILFAT",.F.,.F.,{_cFil, aFat, lFatura, lBoleto, lDanfeXml})
            endif

            if Empty(cHtml044)
                cHtml044 += '<p>A '+Alltrim(SA1->A1_NOME)+'</p>'
                cHtml044 += '<p>Prezado Cliente,</p>'
                if len(aFat) > 1
                    cHtml044 += '<p>Suas faturas '+cNomEmp+' foram geradas! Verifique arquivos anexo.</p>'
                else
                    cHtml044 += '<p>Sua fatura '+cNomEmp+' foi gerada! Verifique arquivos anexo.</p>'
                endif
                
                if len(aFat) == 1
                    cHtml044 += '<p></p>'
                    cHtml044 += '<p>Fatura: '+cFatura+'</p>'
                    cHtml044 += '<p></p>'
                else
                    cHtml044 += '<p></p>'
                    cHtml044 += '<p>Faturas neste email:</p>'
                    cHtml044 += '<p>'
                    for nI := 1 to len(aFat)
                        cHtml044 += aFat[nI][1]+iif(!empty(aFat[nI][5]),'-'+aFat[nI][5],'')+'<br />'
                    next nI
                    cHtml044 += '</p>'
                    cHtml044 += '<p></p>'
                endif

                cHtml044 += '<p>Agradecemos a preferencia.</p>'
                cHtml044 += '<p>'+cNomEmp+'</p>'
            endif

            if !(isBlind())
                
                lEnvioOK:=.F.
                cEmails := PadR(cEmails, nTamEmail)
                cAssunto := PadR(cAssunto, 200)

                DEFINE MSDIALOG oDlgMail TITLE "Envio de Email" FROM 000, 000  TO 600, 800 COLORS 0, 16777215 PIXEL

                @ 005, 005 SAY oSayMail3 PROMPT "Fatura:" SIZE 025, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
                @ 012, 005 MSGET oFatura VAR cFatura SIZE 050, 010 OF oDlgMail COLORS 0, 16777215 PIXEL WHEN .F.

                @ 005, 060 SAY oSayMail4 PROMPT "Cliente" SIZE 025, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
                @ 012, 060 MSGET oCliente VAR SA1->A1_NOME SIZE 325, 010 OF oDlgMail COLORS 0, 16777215 PIXEL WHEN .F.

                @ 034, 005 SAY oSayMail1 PROMPT "E-mail destino:" SIZE 080, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
                @ 042, 005 MSGET oGetMail VAR cEmails SIZE 385, 010 OF oDlgMail COLORS 0, 16777215 PIXEL

                @ 057, 005 SAY oSayMail1 PROMPT "Assunto:" SIZE 025, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
                @ 065, 005 MSGET oGetAss VAR cAssunto SIZE 385, 010 OF oDlgMail COLORS 0, 16777215 PIXEL

                @ 090, 005 SAY oSayMail2 PROMPT "Mensagem Email:" SIZE 063, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
                @ 100, 005 GET oGetMsgMail VAR cHtml044 OF oDlgMail MULTILINE SIZE 385, 90 COLORS 0, 16777215 HSCROLL PIXEL
                oGetMsgMail:Hide()

                //Cria o componente que irá carregar o preview do HTML
                @ 092, 005 SAY oSayMail3 PROMPT Replicate("_",600) SIZE 385, 007 OF oDlgMail COLORS 0, CLR_GRAY PIXEL
                @ 184, 005 SAY oSayMail4 PROMPT Replicate("_",600) SIZE 385, 007 OF oDlgMail COLORS 0, CLR_GRAY PIXEL
                oWebEngine := TWebEngine():New(oDlgMail, 100, 005, 385, 90,/*cUrl*/, oWebChannel::connect())
                oWebEngine:SetHtml( cHtml044 )
                @ 086, 330 BUTTON oBtnHTML PROMPT "Alterar Mensagem" SIZE 060, 010 OF oDlgMail PIXEL ACTION AltHtml()

                @ 196, 005 SAY oSayMail5 PROMPT "Anexos:" SIZE 025, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
                oMsGetArq := MsNewGetArq(oDlgMail, 203, 005, 280, 390, aArqEmail)

                @ 285, 005 BUTTON oBtnMail1 PROMPT "+ Anexar" SIZE 040, 012 OF oDlgMail PIXEL ACTION DoAnexo()
                @ 285, 050 BUTTON oBtnMail1 PROMPT "Exclui Anexo" SIZE 045, 012 OF oDlgMail PIXEL ACTION DoExcAnexo()
                @ 285, 355 BUTTON oBtnMail1 PROMPT "Enviar" SIZE 037, 012 OF oDlgMail PIXEL ACTION (lEnvioOK:=.T., oDlgMail:End())
                @ 285, 310 BUTTON oBtnMail2 PROMPT "Cancelar" SIZE 037, 012 OF oDlgMail PIXEL ACTION (lEnvioOK:=.F., oDlgMail:End())

                ACTIVATE MSDIALOG oDlgMail CENTERED

                if lEnvioOK
                    AjuHtml()
                    aArqAux := aClone(aArqEmail)
                    aArqEmail := {}
                    for nI := 1 to len(oMsGetArq:aCols)
                        if !oMsGetArq:aCols[nI][3] .AND. !empty(oMsGetArq:aCols[nI][1]) //nao deletado
                            aadd(aArqEmail, aArqAux[nI])
                        endif
                    next nI
                    if empty(aArqEmail)
                        lEnvioOK := .F.
                    endif

                    cAssunto := Alltrim(cAssunto)
                    cHtml044 := Alltrim(cHtml044)
                    cEmails := Alltrim(cEmails)
                endif
            endif

            //Parâmetros necessários para funcao GPEMail funcionar
            // MV_RELACNT - Conta a ser utilizada no envio de E-Mail
            // MV_RELFROM - E-mail utilizado no campo FROM no envio
            // MV_RELSERV - Nome do Servidor de Envio de E-mail utilizado no envio
            // MV_RELAUTH - Determina se o Servidor de Email necessita de Autenticação
            // MV_RELAUSR - Usuário para Autenticação no Servidor de Email
            // MV_RELAPSW - Senha para Autenticação no Servidor de Email
            // MV_XMAILEX - Email destinatário
            if lEnvioOK 
                lEnvioOK := GPEMail(cAssunto, cHtml044, cEmails, aArqEmail)

                if lEnvioOK
                    For nI := 1 to len(aFat)
                        if len(aFat[nI])>=7
                            SE1->(DbGoTo(aFat[nI][7]))
                            If RecLock('SE1',.F.)
                                SE1->E1_FLAGFAT := "E"
                                SE1->(MsUnlock())
                            EndIf
                        else
                            SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
                            if SE1->(DbSeek(xFilial("SE1")+aFat[nI][4]+aFat[nI][1]+aFat[nI][5]+aFat[nI][6] ))
                                If RecLock('SE1',.F.)
                                    SE1->E1_FLAGFAT := "E"
                                    SE1->(MsUnlock())
                                EndIf
                            endif
                        endif

                        if lLogMail
                            GrvLog(cEmails, aArqEmail) //grava log envio email na U0J
                        endif
                    next nI
                endif

                if lEnvioOK .AND. !empty(cCc)
                    GPEMail(cAssunto, cHtml044, cCc, aArqEmail)
                endif
            endif
        //else
        //    if !(isBlind())
        //        MsgInfo("Não foram encontrados arquivos a enviar. Tente imprimir a fatura/boleto novamente para geração do arquivo.", "Atenção")
        //    endif
        //    lEnvioOK := .F.
        //Endif
    else
        //JOB e cliente nao configurado email
        lEnvioOK := .F.
    endif

    //excluo os anexos para nao pesar o server
    ExcAnexos()

Return lEnvioOK 

Static Function AltHtml()

    if !lHtmlShow
        oWebEngine:Hide()
        oGetMsgMail:Show()
        oBtnHTML:cCaption := "Ver Mensagem"
    else
        AjuHtml()
        oGetMsgMail:hide()
        oWebEngine:SetHtml( cHtml044 )
        oWebEngine:Show()
        oBtnHTML:cCaption := "Alterar Mensagem"
    endif

    lHtmlShow := !lHtmlShow 

Return

Static Function AjuHtml()
    cHtml044 := StrTran(cHtml044,Chr(13)+Chr(10))
Return

//---------------------------------------------------------------------
// Definicao do grid de arquivos
//---------------------------------------------------------------------
Static Function MsNewGetArq(oPnl, nTop, nLeft, nBottom, nRight, aFiles)

    Local nI, nPos
	Local aHeaderEx 	:= {}
	Local aColsEx 		:= {}
	Local aFieldFill 	:= {}
	Local aAlterFields 	:= {}

	AAdd(aHeaderEx, {"Arquivo","ARQUIVO","",200,0,"","€€€€€€€€€€€€€€","C","","","",""})

    for nI := 1 to len(aFiles)
        nPos := RAT("\",aFiles[nI]) + 1
        aFieldFill := {}
        AAdd(aFieldFill, SubStr(aFiles[nI],nPos))
        AAdd(aFieldFill, "") //nome do arquivo anexo local
        AAdd(aFieldFill, .F.) // Delete
        AAdd(aColsEx, aFieldFill)
    next nI

Return MsNewGetDados():New( nTop, nLeft, nBottom, nRight, GD_DELETE , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPnl, aHeaderEx, aColsEx)


Static Function DoAnexo()

    Local cArquivos := ""
    Local cFileNameDes
    Local cDirDes := SuperGetMv("MV_XDIRANX",.F.,"arquivos_mo\anexos\") //destino dos arquivos (arquivos_mo\anexos\)
    Local cMask := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
    Local nX := 1
    Local nSeq := 1
    Local lUpload := .F.
    Local cExtensao := ""
    Local cDirClient := FWGetProfString("TRETE044", "DIRCLIENT", 'C:\', .T.)
    Local aFilesRet := {}

    cArquivos := tFileDialog( "Todos Arquivos (*.*) | Arquivos PDF (*.pdf)",'Selecao de Arquivos',, cDirClient, .F., GETF_MULTISELECT )
    if empty(cArquivos)
        Return
    endif
    
    aFilesRet := StrToKArr(cArquivos, ";")
    for nX := 1 to len(aFilesRet)
        if !File(aFilesRet[nX])
            MsgInfo("Arquivo "+aFilesRet[nX]+" não encontrado!")
            Return
        endif    
    next nX

    //gravo profile a pasta dos aruiqovos selecionados
    if RAT("\",aFilesRet[1]) > 0
        cDirClient := SubStr(aFilesRet[1],1,RAT("\",aFilesRet[1]))
    elseif RAT("/",aFilesRet[1]) > 0
        cDirClient := SubStr(aFilesRet[1],1,RAT("/",aFilesRet[1]))
    endif
    FwWriteProfString( "TRETE044", "DIRCLIENT", cDirClient, .T. )

    cDirDes := "system\"+cDirDes

    for nX := 1 to len(aFilesRet)

        if RAT("\",aFilesRet[nX]) > 0
            cFileNameDes := SubStr(aFilesRet[nX],RAT("\",aFilesRet[nX])+1)
        elseif RAT("/",aFilesRet[nX]) > 0
            cFileNameDes := SubStr(aFilesRet[nX],RAT("/",aFilesRet[nX])+1)
        endif

        //tratamentos no nome do arquivo
        cExtensao := SubStr(cFileNameDes , RAT(".",cFileNameDes) )
        cFileNameDes := SubStr(cFileNameDes , 1, RAT(".",cFileNameDes)-1 )
        cFileNameDes := StrTran(cFileNameDes," ","_")
        cFileNameDes := U_MYNOCHAR(cFileNameDes, cMask)
        While File(cDirDes + cFileNameDes + cExtensao)
            cFileNameDes := "anexo"+cValToChar(nSeq) + "_" + cFileNameDes
            nSeq++
        Enddo
        
        FWMsgRun(, {|| lUpload := __CopyFile(aFilesRet[nX], cDirDes + cFileNameDes + cExtensao) }, 'Aguarde','fazendo upload arquivos... ('+cValToChar(nX)+'/'+cValToChar(len(aFilesRet))+')')

        If lUpload
            aadd(aArqEmail, cDirDes + cFileNameDes + cExtensao )
            aadd(aArqAnex, cDirDes + cFileNameDes + cExtensao )

            //ajuste para caso nao puxe nenhum arquivo, e vai anexar na mão.
            if len(oMsGetArq:aCols) == 1 .AND. empty(oMsGetArq:aCols[1][1])
                oMsGetArq:aCols := {}
            endif
            aadd(oMsGetArq:aCols, {cFileNameDes + cExtensao, aFilesRet[nX], .F.})
        else
            MsgInfo("Falha ao anexar arquivo ["+aFilesRet[nX]+"] no servidor.")
        EndIf
    
    next nX

    oMsGetArq:oBrowse:Refresh()

Return

Static Function DoExcAnexo()

    Local cDirDes := SuperGetMv("MV_XDIRANX",.F.,"arquivos_mo\anexos\") //destino dos arquivos (arquivos_mo\anexos\)
    Local nPosAux := 0
    
    cDirDes := "system\"+cDirDes

    if !empty(oMsGetArq:aCols[oMsGetArq:nAt][1])
        if !empty(oMsGetArq:aCols[oMsGetArq:nAt][2]) //significa que é um anexo do usuario
            if File(cDirDes+oMsGetArq:aCols[oMsGetArq:nAt][1])
                FErase(oMsGetArq:aCols[oMsGetArq:nAt][1])
            endif
        endif

        nPosAux := aScan(aArqEmail, {|cFile| oMsGetArq:aCols[oMsGetArq:nAt][1] $ cFile })
        if nPosAux > 0
            aDel(aArqEmail, nPosAux)
            aSize(aArqEmail, len(aArqEmail)-1)
        endif
        nPosAux := aScan(aArqAnex, {|cFile| oMsGetArq:aCols[oMsGetArq:nAt][1] $ cFile })
        if nPosAux > 0
            aDel(aArqAnex, nPosAux)
            aSize(aArqAnex, len(aArqAnex)-1)
        endif

        aDel(oMsGetArq:aCols, oMsGetArq:nAt)
        aSize(oMsGetArq:aCols, len(oMsGetArq:aCols)-1)

        if len(oMsGetArq:aCols) == 0
            aadd(oMsGetArq:aCols, {"","",.F.})
        endif

        oMsGetArq:oBrowse:Refresh()
    endif

Return

Static Function ExcAnexos()
    
    Local nX := 1 
    
    for nX := 1 to len(aArqAnex)
        if File(aArqAnex[nX])
            FErase(aArqAnex[nX])
        endif
    next nX

Return


//pega os arquivos a serem anexados
Static Function GetArqPDF(_cFil, aFat, lFatura, lBoleto, lDanfeXml)

    Local lAux := .T.
    Local nAt, nQtdArq, nX, nI, nQtdFat
    Local aArqRet := {}
    Local cDirDes
    Local cDirSrv 
    Local aDirAux
    Local cArqRet := ""
    Local cChvTit			:= ""
    Local cNomeCli
    Local aNfCup := {}
    Local cMask := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
    Local cFImpFat := SuperGetMv("MV_XFUNFAT",.F.,"TRETE020") //fonte para impressao da fatura
    Local cFImpBol := SuperGetMv("MV_XFUNBOL",.F.,"TRETR009") //fonte para impressao de boletos
    Local cBlFuncFat, cBlFuncBol
    Local aBoleto := {}
    Local aAuxFat := {}

    //ordeno o array de faturas por cliente + numero + parcela
    ASort(aFat,,,{|x,y| x[2] + x[3] + x[1] + x[5] < y[2] + y[3] + y[1] + y[5] })

    if lFatura
        
        cChvTit			:= aFat[1][1]
        aAuxFat 		:= {}
        nQtdFat			:= Len(aFat)

        For nI := 1 To nQtdFat
            aadd(aAuxFat, {aFat[nI][1],aFat[nI][2],aFat[nI][3],aFat[nI][4],aFat[nI][5],aFat[nI][6]} )

            if nI+1 <= nQtdFat
                cChvTit			:= aFat[nI+1][1]
            endif

            if cChvTit <> aFat[nI][1] .OR. nI == nQtdFat

                cArqRet := ""
                cDirDes := SuperGetMv("MV_XDIRFAT",.F.,"arquivos_mo\faturas\") //destino dos arquivos (arquivos_mo\faturas\)
                cDirSrv := "system\" + cDirDes

                //procura arquivo com esse prfixo de nome (filial+fatura+cliente+loja)
                cNomeArq	:= "FATURA_" + Alltrim(xFilial("SE1",_cFil)) + "_" + Alltrim(aFat[nI][1]) + "_" + Alltrim(aFat[nI][2]) + Alltrim(aFat[nI][3]) + "_"

                aDirAux := Directory(cDirSrv+cNomeArq+'*.pdf')

                //Percorre os arquivos, do ultimo para o primeiro
                nQtdArq := Len(aDirAux)
                For nAt := nQtdArq To 1 STEP -1
                    //Pegando o nome do arquivo
                    cFileAt := aDirAux[nAt][1]

                    if UPPER(cNomeArq) $ UPPER(cFileAt)
                        cArqRet := cFileAt
                        EXIT
                    endif

                Next nAt

                if empty(cArqRet)//tenta gerar caso nao encontre
                    cNomeCli 	:= Posicione("SA1",1,xFilial("SA1")+aFat[nI][2]+aFat[nI][3],"A1_NREDUZ")
                    cNomeArq	:= "FATURA_" + Alltrim(xFilial("SE1",_cFil)) + "_" + Alltrim(aFat[nI][1]) + "_" + Alltrim(aFat[nI][2]) + Alltrim(aFat[nI][3]) + "_" + Upper(AllTrim(cNomeCli)) + "_" +;
                                    SubStr(DToS(dDataBase),7,2) + SubStr(DToS(dDataBase),5,2) + SubStr(DToS(dDataBase),1,4)

                    //trato nome arquivo 
                    cNomeArq := StrTran(cNomeArq," ","_")
                    cNomeArq := U_MYNOCHAR(cNomeArq, cMask)

                    //Gera arquivo PDF da Fatura
                    //U_TRETE020(,cFilAnt,{{aFat[nI][1],aFat[nI][2],aFat[nI][3],aFat[nI][4],aFat[nI][5],aFat[nI][6]}},.T.,,,,iif(Type("cGet25")=="C",cGet25,""))
                    cBlFuncFat := "{|oSay| U_"+cFImpFat+"(,cFilAnt,aAuxFat,.T.,,,," + iif(Type("cGet25")=="C","cGet25","") + ") }"
                    FWMsgRun(, &cBlFuncFat, 'Aguarde','Gerando PDF da fatura...')

                    if File(cDirSrv + cNomeArq + ".pdf")
                        cArqRet := cNomeArq + ".pdf"
                    endif
                endif

                if !Empty(cArqRet)
                    aadd(aArqRet, cDirSrv + cArqRet )
                endif

                aAuxFat := {}
            endif
        Next nI

    endif

    if lBoleto 

        cChvTit			:= aFat[1][1]
        aAuxFat 		:= {}
        nQtdFat			:= Len(aFat)

        For nI := 1 To nQtdFat
            aadd(aAuxFat, {aFat[nI][1],aFat[nI][2],aFat[nI][3],aFat[nI][4],aFat[nI][5],aFat[nI][6]} )

            if nI+1 <= nQtdFat
                cChvTit			:= aFat[nI+1][1]
            endif

            if cChvTit <> aFat[nI][1] .OR. nI == nQtdFat
            
                cArqRet := ""
                cDirDes := SuperGetMv("MV_XDIRBMO",.F.,"arquivos_mo\boletos\") //destino dos arquivos (arquivos_mo\boletos\)
                cDirSrv := "system\" + cDirDes

                //procura arquivo com esse prfixo de nome (filial+fatura+cliente+loja)
                cNomeArq	:= "BOLETO_" + Alltrim(xFilial("SE1",_cFil)) + "_" + Alltrim(aFat[nI][1]) + "_" + Alltrim(aFat[nI][2]) + Alltrim(aFat[nI][3]) + "_"

                aDirAux := Directory(cDirSrv+cNomeArq+'*.pdf')

                //Percorre os arquivos, do ultimo para o primeiro
                nQtdArq := Len(aDirAux)
                For nAt := nQtdArq To 1 STEP -1
                    //Pegando o nome do arquivo
                    cFileAt := aDirAux[nAt][1]

                    if UPPER(cNomeArq) $ UPPER(cFileAt)
                        cArqRet := cFileAt
                        EXIT
                    endif

                Next nAt

                if empty(cArqRet) //tentar gerar
                    aBoleto := MontaABol(aAuxFat)
                    if !empty(aBoleto)
                        //FWMsgRun(,{|oSay| U_TRETR009(aBoleto,,,,.F.)},'Aguarde','Imprimindo boleto bancário...')
                        cBlFuncBol := "{|oSay| U_"+cFImpBol+"(aBoleto,,,.T.,.F.)}"
                        FWMsgRun(, &cBlFuncBol ,'Aguarde','Gerando PDF boleto bancário...')

                        //busco novamente
                        aDirAux := Directory(cDirSrv+cNomeArq+'*.pdf')
                        cArqRet := iif(len(aDirAux)>=1, aDirAux[1][1], "")

                        if empty(cArqRet)
                            MsgInfo("Não foi possível gerar PDF do boleto bancário. Tente gerar manualmente.", "Atenção")
                        endif
                    endif
                endif

                if !Empty(cArqRet)
                    aadd(aArqRet, cDirSrv + cArqRet )
                endif

                aAuxFat := {}
            endif
        Next nI

    endif

    if lDanfeXml

        for nI := 1 to len(aFat)

            //verifico se há NFs de cupom (ou NFe) a anexar                 {cFil, cPref, cTit, cParc, cTp, cCli, cLojaCli}
            aNfCup := U_TRE018NF(.T./*_lFatura*/, .T./*lGetList*/, {_cFil, aFat[nI][4], aFat[nI][1], aFat[nI][5], aFat[nI][6], aFat[nI][2], aFat[nI][3]}, .T.)

            For nX := 1 to len(aNfCup)

                cDirDes := Alltrim(SuperGetMV("MV_XDIRDAN",.T.,"arquivos_mo\danfes\")) //destino dos arquivos 
                cDirSrv := "system\" + cDirDes

                //posiciono na NF
                SF2->(DbGoTo(aNfCup[nX][5]))
                if SF2->(!Eof()) .AND. !empty(SF2->F2_CHVNFE)

                    //DANFE
                    cNomeArq	:= SF2->F2_CHVNFE + "-nfe.pdf"
                    if aScan(aArqRet, {|cFile| cDirSrv + cNomeArq == cFile }) == 0
                        if File(cDirSrv + cNomeArq)
                            aadd(aArqRet, cDirSrv + cNomeArq )
                        else
                            //Gera arquivo PDF do DANFE
                            FWMsgRun(,{|oSay| lAux := fGerDanf(cDirSrv, cNomeArq) },'Aguarde','Gerando PDF da DANFE...')

                            if lAux
                                aadd(aArqRet, cDirSrv + cNomeArq )
                            endif
                        endif
                    endif

                    //XML
                    cNomeArq	:= SF2->F2_CHVNFE + "-nfe.xml"
                    if aScan(aArqRet, {|cFile| cDirSrv + cNomeArq == cFile }) == 0
                        if File(cDirSrv + cNomeArq)
                            aadd(aArqRet, cDirSrv + cNomeArq )
                        else
                            //Gera arquivo XML da nota
                            FWMsgRun(,{|oSay| lAux := fGerXml(cDirSrv, cNomeArq) },'Aguarde','Gerando XML da nota...')

                            if lAux
                                aadd(aArqRet, cDirSrv + cNomeArq )
                            endif
                        endif
                    endif
                endif
            next nX

        next nI

    endif

Return aArqRet

Static Function MontaABol(aFat)

    Local aArea := GetArea()
    Local aAreaSE1 := SE1->(GetArea())
    Local aBoleto := {}

    if len(aFat[1])>=7
        SE1->(DbGoTo(aFat[1][7]))
    else
        SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
        if SE1->(DbSeek(xFilial("SE1")+aFat[1][4]+aFat[1][1]+aFat[1][5]+aFat[1][6] ))
        endif
    endif

    if SE1->(!Eof()) .AND. !empty(SE1->E1_NUMBCO) //verifico se ja tem o nosso numero

        AAdd(aBoleto,SE1->E1_PREFIXO) 						            //Prefixo - De
        AAdd(aBoleto,SE1->E1_PREFIXO) 						            //Prefixo - Ate
        AAdd(aBoleto,SE1->E1_NUM)	 					            //Numero - De
        AAdd(aBoleto,SE1->E1_NUM)	 					            //Numero - Ate
        AAdd(aBoleto,SE1->E1_PARCELA) 						            //Parcela - De
        AAdd(aBoleto,aFat[len(aFat)][5]) 						            //Parcela - Ate
        AAdd(aBoleto,SE1->E1_PORTADO) 						    //Portador - De
        AAdd(aBoleto,SE1->E1_PORTADO) 						    //Portador - Ate
        AAdd(aBoleto,SE1->E1_CLIENTE)				 					//Cliente - De
        AAdd(aBoleto,SE1->E1_CLIENTE)				 					//Cliente - Ate
        AAdd(aBoleto,SE1->E1_LOJA)			 						//Loja - De
        AAdd(aBoleto,SE1->E1_LOJA)			 						//Loja - Ate
        AAdd(aBoleto,SE1->E1_EMISSAO)					        //Emissão - De
        AAdd(aBoleto,SE1->E1_EMISSAO)					        //Eemissão- Ate
        AAdd(aBoleto,DataValida(SE1->E1_VENCTO))		        //Vencimento - De
        
        //vou para o ultimo titulo
        if len(aFat) > 1
            if len(aFat[len(aFat)])>=7
                SE1->(DbGoTo(aFat[len(aFat)][7]))
            else
                SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
                if SE1->(DbSeek(xFilial("SE1")+aFat[len(aFat)][4]+aFat[len(aFat)][1]+aFat[len(aFat)][5]+aFat[len(aFat)][6] ))
                endif
            endif
        endif
        AAdd(aBoleto,DataValida(SE1->E1_VENCTO))		        //Vencimento - Ate
        AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 			//Nr. Bordero - De
        AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) 	//Nr. Bordero - Ate
        AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 				//Carga - De
        AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 		//Carga - Ate
        AAdd(aBoleto,"") 										//Mensagem 1
        AAdd(aBoleto,"") 										//Mensagem 2
    
    endif

    RestArea(aAreaSE1)
    RestArea(aArea)

Return aBoleto


//Função responsavel por gerar os danfes.
Static Function fGerDanf(cDirSrv, cFilePrint)

	Local oBjNfe 
	Local cIdEnt    := ""
	Local nRet		:= 0
    Local cBkpFilAnt := cFilAnt
	Local aArea		:= GetArea()
	Local aAreaSM0	:= SM0->(GetArea())
    Local cDirSpool := SuperGetMV('MV_RELT',,"\SPOOL\")

    cFilAnt := SF2->F2_FILIAL

	SM0->(dbSeek(cEmpAnt+cFilAnt))
	cIdEnt := GetIdEnt()

	If Empty(cIdEnt)
        cFilAnt := cBkpFilAnt
		RestArea(aAreaSM0)
		RestArea(aArea)
		Return(.F.)
	EndIf

    oBjNfe:= FWMSPrinter():New(cFilePrint, 6,.F.,cDirSpool,.T.,.F.,,,.T.,.F.,,.F.,)
    
    oBjNfe:SetResolution(78) //Tamanho estipulado para o DANFE
    oBjNfe:SetPortrait()
    oBjNfe:SetPaperSize(DMPAPER_A4)
    oBjNfe:SetMargin(60,60,60,60)
    oBjNfe:cPathPDF := cDirSpool //Pasta no servidor que Ã© utilizada para salvamento temporÃ¡rio dos PDFs.

    if FILE(cDirSpool+cFilePrint)
        FErase(cDirSpool+cFilePrint)
    ENDIF

    //Chamada da função padrão de impressão de danfe
    if U_PrtNfeSef(cIdEnt,"","",oBjNfe,,cFilePrint,.T./*lIsLoja*/,)
        
        Conout("Danfe gravado com sucesso!")

        If __CopyFile(cDirSpool + cFilePrint, cDirSrv + cFilePrint)
            //conout(" >> Copiado arquivo <"+cDirSpool + cFilePrint + ".pdf"+"> para o diretorio do Posto On-Line: "+cDirSrv + cFilePrint + ".pdf")
        EndIf

        If FErase(cDirSpool + cFilePrint) == 0
            //conout(" >> Excluido arquivo <"+cDirSpool + cFilePrint + ".pdf"+">")
        EndIf

        if File(cDirSrv + cFilePrint)
            nRet++ 
        endif

    else
        Conout("Erro ao gravar danfe.")
    endif

    cFilAnt := cBkpFilAnt
	RestArea(aAreaSM0)
	RestArea(aArea)

Return(nRet > 0)


//Função responsavel por gerar o xml e gravar.
Static Function fGerXml(cDirSrv, cNomeArq)

	Local nContArq	:= 0
	Local nX
	Local cURL     	:= ""
	Local cModelo	:= ""
	Local nHandle  	:= 0
	Local oRetorno
	Local oWS
	Local oXML, oAux
	Local cXML		:= ""
	Local lOk      	:= .F.
    Local aArea		:= GetArea()
	Local aAreaSM0	:= SM0->(GetArea())
    Local cBkpFilAnt := cFilAnt

	cFilAnt := SF2->F2_FILIAL
    SM0->(dbSeek(cEmpAnt+cFilAnt))

    //verifico se vem do Kingposto, e sem tem o XML gravado
	MHQ->(DbSetOrder(1)) //MHQ_FILIAL+MHQ_ORIGEM+MHQ_CPROCE+MHQ_CHVUNI+MHQ_EVENTO+DTOS(MHQ_DATGER)+MHQ_HORGER
	if MHQ->(DbSeek(xFilial("MHQ")+PadR("KINGPOSTO",TamSX3("MHQ_ORIGEM")[1])+PadR("XML",TamSX3("MHQ_CPROCE")[1])+SF2->F2_FILIAL+SF2->F2_SERIE+SF2->F2_DOC ))
		cXML := MHQ->MHQ_MENSAG
        cChvNFe := NfeIdSPED(cXML,"Id")
        if FILE(cDirSrv+SubStr(cChvNFe,4,44)+"-nfe.xml")
            FErase(cDirSrv+SubStr(cChvNFe,4,44)+"-nfe.xml")
        ENDIF

        nHandle := FCreate(cDirSrv+SubStr(cChvNFe,4,44)+"-nfe.xml")
        If nHandle > 0
            FWrite(nHandle, cXML )
            FClose(nHandle)

            nContArq++
        EndIf
        
        if nContArq > 0
            cFilAnt := cBkpFilAnt
            RestArea(aAreaSM0)
            RestArea(aArea)
            Return( nContArq > 0 )
        endif
	endif

	cIdEnt := GetIdEnt()

	If Empty(cIdEnt)
        cFilAnt := cBkpFilAnt
		RestArea(aAreaSM0)
		RestArea(aArea)
		Return(.F.)
	EndIf

	cURL := GetNewPar("MV_SPEDURL","http://")
    //PadR(GetNewPar("MV_NFCEURL","http://")

	oWS:= WSNFeSBRA():New()
	oWS:cUSERTOKEN        	:= "TOTVS"
	oWS:cID_ENT           	:= GetIdEnt()
	oWS:_URL              	:= AllTrim(cURL)+"/NFeSBRA.apw"
	oWS:cIdInicial        	:= SF2->F2_SERIE + SF2->F2_DOC 
	oWS:cIdFinal          	:= SF2->F2_SERIE + SF2->F2_DOC 
	oWS:dDataDe           	:= SF2->F2_EMISSAO 
	oWS:dDataAte          	:= SF2->F2_EMISSAO 
	oWS:cCNPJDESTInicial  	:= "              "
	oWS:cCNPJDESTFinal    	:= "99999999999999"
	oWS:nDiasparaExclusao 	:= 0

	lOk			:= oWS:RETORNAFX()
	oRetorno	:= oWS:oWsRetornaFxResult

	If lOk

		For nX := 1 To Len(oRetorno:OWSNOTAS:OWSNFES3)

			oXml    := oRetorno:OWSNOTAS:OWSNFES3[nX]
			oXmlExp := XmlParser(oRetorno:OWSNOTAS:OWSNFES3[nX]:OWSNFE:CXML,"","","")
			cXML	:= ""
			//cVerNfe := IIF(retType("oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT") <> "U", oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT, '')
            cVerNfe	:= ""
            if (oAux := XmlChildEx(oXmlExp,"_NFE"))!=Nil .AND. ;
                (oAux := XmlChildEx(oAux,"_INFNFE"))!=Nil .AND. ;
                (oAux := XmlChildEx(oAux,"_VERSAO"))!=Nil 

                cVerNfe := oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT
            endif

			If !Empty(oXml:oWSNFe:cProtocolo)

				cChvNFe := NfeIdSPED(oXml:oWSNFe:cXML,"Id")
				cModelo := cChvNFe
				cModelo := StrTran(cModelo,"NFe","")
				cModelo := StrTran(cModelo,"CTe","")
				cModelo := SubStr(cModelo,21,02)

				Do Case
					Case cModelo == "65"
					cPrefixo := "NFCe"
					OtherWise
					If '<cStat>301</cStat>' $ oXml:oWSNFe:cxmlPROT .or. '<cStat>302</cStat>' $ oXml:oWSNFe:cxmlPROT
						cPrefixo := "den"
					Else
						cPrefixo := "NFe"
					Endif
				EndCase

				if FILE(cDirSrv+SubStr(cChvNFe,4,44)+"-nfe.xml")
					FErase(cDirSrv+SubStr(cChvNFe,4,44)+"-nfe.xml")
				ENDIF

				nHandle := FCreate(cDirSrv+SubStr(cChvNFe,4,44)+"-nfe.xml")

				If nHandle > 0

					cCab1 := '<?xml version="1.0" encoding="UTF-8"?>'
					Do Case
						Case cVerNfe <= "1.07"
						cCab1 += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.portalfiscal.inf.br/nfe procNFe_v1.00.xsd" versao="1.00">'
						Case cVerNfe >= "2.00" .And. "cancNFe" $ oXml:oWSNFe:cXML
						cCab1 += '<procCancNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + cVerNfe + '">'
						OtherWise
						cCab1 += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + cVerNfe + '">'
					EndCase
					cRodap := '</nfeProc>'

					FWrite(nHandle,AllTrim(cCab1))
					FWrite(nHandle,AllTrim(oXml:oWSNFe:cXML))
					FWrite(nHandle,AllTrim(oXml:oWSNFe:cXMLPROT))
					FWrite(nHandle,AllTrim(cRodap))
					FClose(nHandle)

					nContArq++
				EndIf
			Endif

			FreeObj(oXML)
			FreeObj(oXmlExp)
		Next nX
	Endif

	FreeObj(oWS)
	FreeObj(oRetorno)

	if nContArq > 0
		//Conout("Arquivo exportado com sucesso!")
	else
		//Conout("Erro ao exportar xml!")
	endif

    cFilAnt := cBkpFilAnt
	RestArea(aAreaSM0)
	RestArea(aArea)

Return( nContArq > 0 )

//Função responsavel por selecionar a entidade referente a nf.
Static Function GetIdEnt()

	Local aArea  := GetArea()
	Local cIdEnt := ""
	Local cURL   := PadR(GetNewPar("MV_SPEDURL","http://"),250)
	Local oWs
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Obtem o codigo da entidade                                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oWS := WsSPEDAdm():New()
	oWS:cUSERTOKEN := "TOTVS"

	oWS:oWSEMPRESA:cCNPJ       := IIF(SM0->M0_TPINSC==2 .Or. Empty(SM0->M0_TPINSC),SM0->M0_CGC,"")
	oWS:oWSEMPRESA:cCPF        := IIF(SM0->M0_TPINSC==3,SM0->M0_CGC,"")
	oWS:oWSEMPRESA:cIE         := SM0->M0_INSC
	oWS:oWSEMPRESA:cIM         := SM0->M0_INSCM
	oWS:oWSEMPRESA:cNOME       := SM0->M0_NOMECOM
	oWS:oWSEMPRESA:cFANTASIA   := SM0->M0_NOME
	oWS:oWSEMPRESA:cENDERECO   := FisGetEnd(SM0->M0_ENDENT)[1]
	oWS:oWSEMPRESA:cNUM        := FisGetEnd(SM0->M0_ENDENT)[3]
	oWS:oWSEMPRESA:cCOMPL      := FisGetEnd(SM0->M0_ENDENT)[4]
	oWS:oWSEMPRESA:cUF         := SM0->M0_ESTENT
	oWS:oWSEMPRESA:cCEP        := SM0->M0_CEPENT
	oWS:oWSEMPRESA:cCOD_MUN    := SM0->M0_CODMUN
	oWS:oWSEMPRESA:cCOD_PAIS   := "1058"
	oWS:oWSEMPRESA:cBAIRRO     := SM0->M0_BAIRENT
	oWS:oWSEMPRESA:cMUN        := SM0->M0_CIDENT
	oWS:oWSEMPRESA:cCEP_CP     := Nil
	oWS:oWSEMPRESA:cCP         := Nil
	oWS:oWSEMPRESA:cDDD        := Str(FisGetTel(SM0->M0_TEL)[2],3)
	oWS:oWSEMPRESA:cFONE       := AllTrim(Str(FisGetTel(SM0->M0_TEL)[3],15))
	oWS:oWSEMPRESA:cFAX        := AllTrim(Str(FisGetTel(SM0->M0_FAX)[3],15))
	oWS:oWSEMPRESA:cEMAIL      := UsrRetMail(RetCodUsr())
	oWS:oWSEMPRESA:cNIRE       := SM0->M0_NIRE
	oWS:oWSEMPRESA:dDTRE       := SM0->M0_DTRE
	oWS:oWSEMPRESA:cNIT        := IIF(SM0->M0_TPINSC==1,SM0->M0_CGC,"")
	oWS:oWSEMPRESA:cINDSITESP  := ""
	oWS:oWSEMPRESA:cID_MATRIZ  := ""
	oWS:oWSOUTRASINSCRICOES:oWSInscricao := SPEDADM_ARRAYOFSPED_GENERICSTRUCT():New()
	oWS:_URL := AllTrim(cURL)+"/SPEDADM.apw"
	If oWs:ADMEMPRESAS()
		cIdEnt  := oWs:cADMEMPRESASRESULT
	Else
		Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"Entidade"},3)
	EndIf

	RestArea(aArea)

Return(cIdEnt)


Static Function GrvLog(cEmails, aArqEmail)

    Local cDetail := ""
    Local nX

    cDetail := "DEST.: "+Alltrim(cEmails) + CRLF
    cDetail += "ANEXOS: " + CRLF
    for nX := 1 to len(aArqEmail)
        cDetail += alltrim(aArqEmail[nX]) + CRLF
    next nX

    DbSelectArea("U0J")

    RecLock("U0J",.T.)
    U0J->U0J_FILIAL := xFilial("U0J")
    U0J->U0J_PROCES := "4"
    U0J->U0J_PREFIX := SE1->E1_PREFIXO
    U0J->U0J_NUM    := SE1->E1_NUM
    U0J->U0J_PARCEL := SE1->E1_PARCELA
    U0J->U0J_TIPO   := SE1->E1_TIPO
    U0J->U0J_MOTIVO := "EMAIL"
    U0J->U0J_OBS    := "ENVIO DE EMAIL DA FATURA"
    U0J->U0J_USER   := cUserName
    U0J->U0J_DATA   := Date()
    U0J->U0J_HORA   := Transform(Time(),"@R 99:99")
    U0J->U0J_DETAIL := cDetail
    U0J->(MsUnlock())

Return
