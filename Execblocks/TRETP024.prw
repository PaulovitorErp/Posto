#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ720PROX
Esse ponto de entrada � chamado para controlar todas as mudan�as de painel.

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

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).
    //Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
    If !lMvPosto
        Return lRet
    EndIf

	If nPanel == 2 //Dados do Documento de Entrada
        lRet := Lj720ValCli(cCodCli,cLojaCli) //Valida o cliente informado pelo usuario
    EndIf

Return lRet

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �Lj720ValCli�Autor  �Vendas Clientes     � Data � 31/10/07   ���
�������������������������������������������������������������������������͹��
���Desc.     �Valida o cliente informado pelo usuario                     ���
�������������������������������������������������������������������������͹��
���Uso       �Loja720                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
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

For nX := 1 To Len(aFilPesq) //varre o cliente padr�o de todas filiais do grupo

    If cEmpAnt == aFilPesq[nX][1]

        cCliPad	 := Eval(bGetMvFil, "MV_CLIPAD", aFilPesq[nX][2]) //SuperGetMV("MV_CLIPAD",,,aFilPesq[nX][2]) // Cliente padrao
        cLojaPad := Eval(bGetMvFil, "MV_LOJAPAD", aFilPesq[nX][2]) //SuperGetMV("MV_LOJAPAD",,,aFilPesq[nX][2]) // Loja do cliente padrao

        //������������������������������������������������Ŀ
        //�Valida se o codigo informado pelo usuario existe�
        //��������������������������������������������������
        lRet := DbSeek(xFilial("SA1")+cCliente+cLoja)

        If !lRet         
            MsgStop("O cliente selecionado n�o est� cadastrado!","Atencao") //"O cliente selecionado n�o est� cadastrado!"
            Exit //Sai do For
        EndIf

        //���������������������������������������������������������������Ŀ
        //�Valida se o cliente a receber o credito eh diferente do cliente�
        //�padrao                                                         �
        //�����������������������������������������������������������������
        If lRet .AND. !Empty(cLoja)
            lRet := (AllTrim(cCliente) <> AllTrim(cCliPad)) .OR. (AllTrim(cLoja) <> AllTrim(cLojaPad))
            If !lRet
                MsgStop("N�o � permitida a troca/devolu��o de mercadorias para o cliente padr�o","Atencao") //"N�o � permitida a troca/devolu��o de mercadorias para o cliente padr�o" ### "Atencao"
                Exit //Sai do For
            EndIf
        EndIf

    EndIf

Next nX

RestArea(aAreaSA1)
RestArea(aArea)

Return lRet
