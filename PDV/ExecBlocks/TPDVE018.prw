#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "MSOBJECT.CH"

/*/{Protheus.doc} User Function TPDVE018

Tratamento para for�ar forma PX e PD aparecer quando o TEF Pagamentos Digitais da Totvs n�o estiver ativo
@type  Function
@author danilo
@since 27/10/2023
@version 1
/*/
User Function TPDVE018()

    Local oBkpTef := STBGetTef() 
    Local oTEF20 := MyLJC_TEF():New() 

    //Fa�o set da classe Fake do TEF para que na valida��o da fun��o STIGetSx5 n�o oculte a forma PX ou PD
    //(cFrmPag == 'PX' .AND. STWChkTef("PX")) - � feita essa valida��o em STIGetSx5
    //oTEF20:oConfig:ISPgtoDig() - � chamado pelo STWChkTef("PX")
    STBSetTef(oTEF20)

    //popula var static (aPaym e aCopyPaym) no fonte STIPAYMENT
    STIGetSx5()

    //Retorno a classe TEF original
    STBSetTef(oBkpTef)

Return 

Class MyLJC_TEF

    Data oConfig
    Data lAtivo
    Method New()

End Class

Method New() Class MyLJC_TEF
    
    Self:oConfig := LJCConfigTef():New()
	Self:lAtivo := .T.

Return Self 


Class LJCConfigTef
    Method New()
    Method ISPgtoDig()
End Class

Method New() Class LJCConfigTef

Return Self 
 
Method ISPgtoDig() Class LJCConfigTef
Local lRet := .T. 
Return lRet
