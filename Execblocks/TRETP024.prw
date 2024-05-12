#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ720PROX
Esse ponto de entrada é chamado para controlar todas as mudanças de painel.

@author Pablo Cavalcante
@since 26/11/2019
@version 1.0
@return lRet

@type function
/*/
User Function TRETP024()

	Local lRet := .T.
    //Local nTpProc := ParamIxb[1]
    Local nPanel := ParamIxb[2]
    //Local nNfOrig := ParamIxb[3]
    Local cCodCli := ParamIxb[4]
    Local cLojaCli := ParamIxb[5]

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
    //Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return lRet
    EndIf

	If nPanel == 2 //Dados do Documento de Entrada
        lRet := Lj720ValCli(cCodCli,cLojaCli) //Valida o cliente informado pelo usuario
    EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Lj720ValCliºAutor  ³Vendas Clientes     º Data ³ 31/10/07   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Valida o cliente informado pelo usuario                     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³Loja720                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function Lj720ValCli(cCliente,cLoja)
Local aArea		:= GetArea()						// Salva posicionamento atual
Local aAreaSA1	:= SA1->(GetArea())				// Salva posicionamento do SA1
Local lRet		:= .T.								// Retorno da funcao
Local cCliPad	:= "" //SuperGetMV("MV_CLIPAD")			// Cliente padrao
Local cLojaPad	:= "" //SuperGetMV("MV_LOJAPAD")		// Loja do cliente padrao
Local aFilPesq   := FWLoadSM0()
Local nX
Local bGetMvFil := {|cPar,cFil| SuperGetMV(cPar,,,cFil) }

DbSelectArea("SA1")
DbSetOrder(1)

For nX := 1 To Len(aFilPesq) //varre o cliente padrão de todas filiais do grupo

    If cEmpAnt == aFilPesq[nX][1]

        cCliPad	 := Eval(bGetMvFil, "MV_CLIPAD", aFilPesq[nX][2]) //SuperGetMV("MV_CLIPAD",,,aFilPesq[nX][2]) // Cliente padrao
        cLojaPad := Eval(bGetMvFil, "MV_LOJAPAD", aFilPesq[nX][2]) //SuperGetMV("MV_LOJAPAD",,,aFilPesq[nX][2]) // Loja do cliente padrao

        //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        //³Valida se o codigo informado pelo usuario existe³
        //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
        lRet := DbSeek(xFilial("SA1")+cCliente+cLoja)

        If !lRet         
            MsgStop("O cliente selecionado não está cadastrado!","Atencao") //"O cliente selecionado não está cadastrado!"
            Exit //Sai do For
        EndIf

        //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        //³Valida se o cliente a receber o credito eh diferente do cliente³
        //³padrao                                                         ³
        //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
        If lRet .AND. !Empty(cLoja)
            lRet := (AllTrim(cCliente) <> AllTrim(cCliPad)) .OR. (AllTrim(cLoja) <> AllTrim(cLojaPad))
            If !lRet
                MsgStop("Não é permitida a troca/devolução de mercadorias para o cliente padrão","Atencao") //"Não é permitida a troca/devolução de mercadorias para o cliente padrão" ### "Atencao"
                Exit //Sai do For
            EndIf
        EndIf

    EndIf

Next nX

RestArea(aAreaSA1)
RestArea(aArea)

Return lRet
