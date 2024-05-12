#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "MSOBJECT.CH"

/*/{Protheus.doc} User Function TPDVE018

Tratamento para forçar forma PX e PD aparecer quando o TEF Pagamentos Digitais da Totvs não estiver ativo
@type  Function
@author danilo
@since 27/10/2023
@version 1
/*/
User Function TPDVE018()

    Local oBkpTef := STBGetTef() 
    Local oTEF20 := MyLJC_TEF():New() 

    //Faço set da classe Fake do TEF para que na validação da função STIGetSx5 não oculte a forma PX ou PD
    //(cFrmPag == 'PX' .AND. STWChkTef("PX")) - É feita essa validação em STIGetSx5
    //oTEF20:oConfig:ISPgtoDig() - é chamado pelo STWChkTef("PX")
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
