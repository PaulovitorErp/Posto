#Include "PROTHEUS.CH"     


/*/{Protheus.doc} SACI008
PE executado apos gravar todos os dados da baixa a receber. 
Neste momento todos os registros já foram atualizados e destravados e a contabilizacao efetuada.

@author Danilo Brito
@since 18/07/2014
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function SACI008()

///////////////////////////////////////////////////////////////////////////////////////////
//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
/////////////////////////////////////////////////////////////////////////////////////////
If ExistBlock("TRETP030")
	ExecBlock("TRETP030",.F.,.F.)
EndIf

Return
