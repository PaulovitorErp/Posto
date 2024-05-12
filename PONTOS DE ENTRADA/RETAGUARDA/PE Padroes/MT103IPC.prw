#include 'protheus.ch'


/*/{Protheus.doc} MT103IPC
Atualiza campos customizados no Documento de Entrada
@author Róger P. Cardoso
@since 25/08/10
@version 1.0
@return lógico

@type function
/*/

User Function MT103IPC()

Local aParam := aClone(Paramixb)
Local cMV_XPECRC := SuperGetMv("MV_XPECRC",,"2") //Qual PE usar para CRC: 1-Sigaloja;2=TotvsPDV

/////////////////////////////////////////////////////////////////////////////////////////
//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                 //
/////////////////////////////////////////////////////////////////////////////////////////
If cMV_XPECRC == "2" .AND. ExistBlock("TRETP031")
	Execblock("TRETP031",.F.,.F.,aParam)
EndIf

  
Return
