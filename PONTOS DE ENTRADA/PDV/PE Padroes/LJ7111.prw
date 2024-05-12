#include 'totvs.ch'

/*/{Protheus.doc} LJ7111
Ponto de entrada para manipular string xml da NFCE

@author thebr
@since 03/09/2019
@version 1.0
@return Nil

@type function
/*/
User Function LJ7111()

    Local aParam := aClone(ParamIxb)
    Local xRet := ParamIxb[1]

	////TODO - não faz nada no PE LJ7111(possivel erro de QRCode)
	////chamado #9805779
	////Assunto: Ocorrência da rejeição 397 (Rejeicao: Parametro do QR-Code divergente da Nota Fiscal Param:1)
	//Return xRet

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP020")
        xRet := ExecBlock("TPDVP020",.F.,.F.,aParam)
	Endif

return xRet
